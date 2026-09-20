/**
 * UdharCard Passkey (WebAuthn / FIDO2) Client-side Helper
 * Fully supports Mobile Biometrics (Fingerprint, Face ID), Screen Patterns, and Device PINs.
 * Includes AbortController management to eliminate "A request is already pending" conflicts.
 */
let activePasskeyAbortController = null;

const PasskeyClient = {
    /**
     * Abort any ongoing WebAuthn prompt or conditional autofill listener.
     */
    abortActiveRequest: function () {
        if (activePasskeyAbortController) {
            try {
                activePasskeyAbortController.abort();
            } catch (e) {}
            activePasskeyAbortController = null;
        }
    },

    /**
     * Check if WebAuthn is supported in current browser & context.
     */
    isSupported: function () {
        return !!(window.PublicKeyCredential &&
            navigator.credentials &&
            navigator.credentials.create &&
            navigator.credentials.get);
    },

    /**
     * Check if biometric / platform authenticator (Fingerprint, Face ID, Screen Pattern/PIN) is available.
     */
    isPlatformAuthenticatorAvailable: async function () {
        if (!this.isSupported()) return false;
        if (typeof PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable === 'function') {
            try {
                return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
            } catch (e) {
                return false;
            }
        }
        return false;
    },

    /**
     * Check if conditional UI (autofill passkey suggestions on inputs) is supported.
     */
    isConditionalMediationAvailable: async function () {
        if (!this.isSupported()) return false;
        if (typeof PublicKeyCredential.isConditionalMediationAvailable === 'function') {
            try {
                return await PublicKeyCredential.isConditionalMediationAvailable();
            } catch (e) {
                return false;
            }
        }
        return false;
    },

    /**
     * Base64URL string to ArrayBuffer.
     */
    base64UrlToBuffer: function (base64Url) {
        if (!base64Url) return new ArrayBuffer(0);
        let base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        while (base64.length % 4) {
            base64 += '=';
        }
        const binary = window.atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) {
            bytes[i] = binary.charCodeAt(i);
        }
        return bytes.buffer;
    },

    /**
     * ArrayBuffer to Base64URL string.
     */
    bufferToBase64Url: function (buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
    },

    /**
     * Parse fetch response safely, handling HTML error pages and non-200 responses gracefully.
     */
    parseResponse: async function (response, fallbackActionName = 'Request') {
        const contentType = response.headers.get('content-type') || '';
        let data = null;

        if (contentType.includes('application/json')) {
            try {
                data = await response.json();
            } catch (err) {
                // Ignore JSON parse error and fallback below
            }
        }

        if (!response.ok) {
            const message = data?.message || (
                response.status === 419
                    ? 'Session or page expired. Please refresh the page and try again.'
                    : `${fallbackActionName} failed (${response.status}: ${response.statusText || 'Server error'}).`
            );
            throw new Error(message);
        }

        if (!data) {
            throw new Error(`${fallbackActionName} returned an unexpected response format from server.`);
        }

        return data;
    },

    /**
     * Register a new Passkey on current device (Fingerprint, Face ID, Pattern, or PIN).
     */
    register: async function (optionsUrl, verifyUrl, name, csrfToken) {
        if (!this.isSupported()) {
            throw new Error('Passkeys are not supported on this browser or device.');
        }

        // Cancel any pending autofill or previous request
        this.abortActiveRequest();
        const controller = new AbortController();
        activePasskeyAbortController = controller;

        try {
            // 1. Fetch challenge options from server
            const optionsResponse = await fetch(optionsUrl, {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || ''
                },
                credentials: 'same-origin',
                signal: controller.signal
            });
            const optionsJson = await this.parseResponse(optionsResponse, 'Passkey options');

            if (!optionsJson.success || !optionsJson.data) {
                throw new Error(optionsJson.message || 'Failed to fetch registration options.');
            }

            const options = optionsJson.data;

            // 2. Format options for navigator.credentials.create()
            options.challenge = this.base64UrlToBuffer(options.challenge);
            options.user.id = this.base64UrlToBuffer(options.user.id);

            if (options.excludeCredentials && Array.isArray(options.excludeCredentials)) {
                options.excludeCredentials = options.excludeCredentials.map(cred => ({
                    ...cred,
                    id: this.base64UrlToBuffer(cred.id)
                }));
            }

            // 3. Prompt user for biometric / pattern / PIN
            let credential;
            try {
                credential = await navigator.credentials.create({
                    publicKey: options,
                    signal: controller.signal
                });
            } catch (e) {
                if (e.name === 'AbortError') {
                    return { success: false, cancelled: true, message: 'Request aborted.' };
                } else if (e.name === 'NotAllowedError') {
                    throw new Error('Passkey registration was cancelled or timed out.');
                } else if (e.name === 'InvalidStateError') {
                    throw new Error('This device or passkey is already registered.');
                }
                throw new Error(e.message || 'Biometric / Screen Lock verification failed.');
            }

            if (!credential) {
                throw new Error('Passkey creation was cancelled.');
            }

            // 4. Extract transports if supported
            let transports = [];
            if (typeof credential.response.getTransports === 'function') {
                transports = credential.response.getTransports();
            }

            // 5. Send credential to backend for verification
            const payload = {
                id: credential.id,
                rawId: this.bufferToBase64Url(credential.rawId),
                type: credential.type,
                name: name || '',
                transports: transports,
                clientDataJSON: this.bufferToBase64Url(credential.response.clientDataJSON),
                attestationObject: this.bufferToBase64Url(credential.response.attestationObject)
            };

            const verifyResponse = await fetch(verifyUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || ''
                },
                credentials: 'same-origin',
                body: JSON.stringify(payload)
            });

            return await this.parseResponse(verifyResponse, 'Passkey registration');
        } finally {
            if (activePasskeyAbortController === controller) {
                activePasskeyAbortController = null;
            }
        }
    },

    /**
     * Authenticate / Login using Passkey (Fingerprint, Face ID, Pattern, or PIN).
     */
    login: async function (optionsUrl, verifyUrl, csrfToken, guard = 'web') {
        if (!this.isSupported()) {
            throw new Error('Passkeys are not supported on this browser or device.');
        }

        // Cancel any pending autofill or previous request to prevent "already pending" error
        this.abortActiveRequest();
        const controller = new AbortController();
        activePasskeyAbortController = controller;

        try {
            const url = optionsUrl + (optionsUrl.includes('?') ? '&' : '?') + 'guard=' + encodeURIComponent(guard);

            // 1. Fetch challenge options
            const optionsResponse = await fetch(url, {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || ''
                },
                credentials: 'same-origin',
                signal: controller.signal
            });
            const optionsJson = await this.parseResponse(optionsResponse, 'Passkey options');

            if (!optionsJson.success || !optionsJson.data) {
                throw new Error(optionsJson.message || 'Failed to fetch login options.');
            }

            const options = optionsJson.data;

            // 2. Format options for navigator.credentials.get()
            options.challenge = this.base64UrlToBuffer(options.challenge);

            if (options.allowCredentials && Array.isArray(options.allowCredentials) && options.allowCredentials.length > 0) {
                options.allowCredentials = options.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64UrlToBuffer(cred.id)
                }));
            } else {
                delete options.allowCredentials; // Allow discoverable / resident credentials
            }

            // 3. Prompt user for biometric / screen lock login
            let assertion;
            try {
                assertion = await navigator.credentials.get({
                    publicKey: options,
                    signal: controller.signal
                });
            } catch (e) {
                if (e.name === 'AbortError') {
                    return { success: false, cancelled: true, message: 'Request aborted.' };
                } else if (e.name === 'NotAllowedError') {
                    throw new Error('Sign-in cancelled or timed out.');
                }
                throw new Error(e.message || 'Biometric verification failed.');
            }

            if (!assertion) {
                throw new Error('Passkey sign-in was cancelled.');
            }

            // 4. Send assertion to backend for verification
            const payload = {
                id: assertion.id,
                rawId: this.bufferToBase64Url(assertion.rawId),
                type: assertion.type,
                clientDataJSON: this.bufferToBase64Url(assertion.response.clientDataJSON),
                authenticatorData: this.bufferToBase64Url(assertion.response.authenticatorData),
                signature: this.bufferToBase64Url(assertion.response.signature),
                userHandle: assertion.response.userHandle ? this.bufferToBase64Url(assertion.response.userHandle) : null
            };

            const verifyResponse = await fetch(verifyUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || ''
                },
                credentials: 'same-origin',
                body: JSON.stringify(payload)
            });

            return await this.parseResponse(verifyResponse, 'Passkey login');
        } finally {
            if (activePasskeyAbortController === controller) {
                activePasskeyAbortController = null;
            }
        }
    },

    /**
     * Start conditional UI autofill listener (for browser auto-suggesting passkey on input focus).
     */
    initAutofill: async function (optionsUrl, verifyUrl, csrfToken, onSuccess, guard = 'web') {
        if (!this.isSupported()) return;
        const available = await this.isConditionalMediationAvailable();
        if (!available) return;

        // If another interactive request is active, do not start autofill
        if (activePasskeyAbortController) return;

        const controller = new AbortController();
        activePasskeyAbortController = controller;

        try {
            const url = optionsUrl + (optionsUrl.includes('?') ? '&' : '?') + 'guard=' + encodeURIComponent(guard);
            const optionsResponse = await fetch(url, {
                headers: {
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken || ''
                },
                credentials: 'same-origin',
                signal: controller.signal
            });
            const optionsJson = await this.parseResponse(optionsResponse, 'Passkey options').catch(() => null);
            if (!optionsJson || !optionsJson.success || !optionsJson.data) return;

            const options = optionsJson.data;
            options.challenge = this.base64UrlToBuffer(options.challenge);
            delete options.allowCredentials;

            const assertion = await navigator.credentials.get({
                publicKey: options,
                mediation: 'conditional',
                signal: controller.signal
            });

            if (assertion) {
                const payload = {
                    id: assertion.id,
                    rawId: this.bufferToBase64Url(assertion.rawId),
                    type: assertion.type,
                    clientDataJSON: this.bufferToBase64Url(assertion.response.clientDataJSON),
                    authenticatorData: this.bufferToBase64Url(assertion.response.authenticatorData),
                    signature: this.bufferToBase64Url(assertion.response.signature),
                    userHandle: assertion.response.userHandle ? this.bufferToBase64Url(assertion.response.userHandle) : null
                };

                const verifyResponse = await fetch(verifyUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': csrfToken || ''
                    },
                    credentials: 'same-origin',
                    body: JSON.stringify(payload)
                });

                const result = await this.parseResponse(verifyResponse, 'Passkey autofill').catch(() => null);
                if (result && result.success && typeof onSuccess === 'function') {
                    onSuccess(result);
                }
            }
        } catch (e) {
            // AbortError is normal when user clicks manual button or navigates away
            if (e.name !== 'AbortError') {
                console.debug('Conditional Passkey listener notice:', e.message);
            }
        } finally {
            if (activePasskeyAbortController === controller) {
                activePasskeyAbortController = null;
            }
        }
    }
};

window.PasskeyClient = PasskeyClient;
