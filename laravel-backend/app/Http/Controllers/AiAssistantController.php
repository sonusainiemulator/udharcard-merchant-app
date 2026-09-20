<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Models\User;

class AiAssistantController extends Controller
{
    /**
     * Handle AI Assistant Queries for Admin and Merchant web users.
     */
    public function query(Request $request)
    {
        $userQuery = trim((string)$request->input('query', ''));
        if (empty($userQuery)) {
            return response()->json([
                'status' => 'error',
                'reply' => 'कृपया कोई सवाल या कमांड दर्ज करें (Please enter a question or command).',
                'suggestions' => $this->getDefaultSuggestions('guest'),
                'actions' => []
            ], 422);
        }

        // Determine user role and context
        $role = 'guest';
        $user = auth()->user();
        $admin = auth('admin')->user();

        if ($admin) {
            $role = 'admin';
        } elseif ($user) {
            $role = ($user->type === 'merchant' || $user->role === 'merchant') ? 'merchant' : 'user';
        }

        // Generate context-aware response
        $response = $this->processQuery($userQuery, $role, $user, $admin);

        return response()->json([
            'status' => 'success',
            'role' => $role,
            'reply' => $response['reply'],
            'suggestions' => $response['suggestions'] ?? $this->getDefaultSuggestions($role),
            'actions' => $response['actions'] ?? []
        ]);
    }

    /**
     * Get quick stats for initial widget load.
     */
    public function quickStats(Request $request)
    {
        $role = 'guest';
        $user = auth()->user();
        $admin = auth('admin')->user();

        $stats = [];
        if ($admin) {
            $role = 'admin';
            $merchantsCount = User::where('type', 'merchant')->count();
            $usersCount = User::where('type', 'user')->count();
            $stats = [
                'total_merchants' => $merchantsCount,
                'total_users' => $usersCount,
                'system_status' => 'Healthy',
            ];
        } elseif ($user && ($user->type === 'merchant' || $user->role === 'merchant')) {
            $role = 'merchant';
            $customerCount = Schema::hasTable('udhar_customers') 
                ? DB::table('udhar_customers')->where('merchant_id', $user->id)->count() 
                : 0;
            $stats = [
                'merchant_name' => $user->firstname . ' ' . $user->lastname,
                'shop_name' => $user->shop_name ?? ($user->business_name ?? 'My Shop'),
                'total_customers' => $customerCount,
                'balance' => $user->balance ?? '0.00',
            ];
        }

        return response()->json([
            'status' => 'success',
            'role' => $role,
            'stats' => $stats,
            'suggestions' => $this->getDefaultSuggestions($role)
        ]);
    }

    /**
     * Core AI Processing & Live Database Resolver.
     */
    protected function processQuery($query, $role, $user, $admin)
    {
        $q = mb_strtolower($query, 'UTF-8');

        // 1. Check for Merchant Counts / Registration Stats (Admin or General query)
        if (str_contains($q, 'merchant') && (str_contains($q, 'kitne') || str_contains($q, 'total') || str_contains($q, 'count') || str_contains($q, 'list') || str_contains($q, 'register'))) {
            $totalMerchants = User::where('type', 'merchant')->count();
            $totalUsers = User::where('type', 'user')->count();
            $recentMerchants = User::where('type', 'merchant')
                ->select('id', 'firstname', 'lastname', 'phone', 'created_at')
                ->orderBy('id', 'desc')
                ->limit(5)
                ->get();

            $reply = "📊 **UdharCard Live Merchant Statistics:**\n\n";
            $reply .= "• **कुल रजिस्टर्ड मर्चेंट्स (Total Merchants):** `{$totalMerchants}`\n";
            $reply .= "• **कुल ग्राहक यूज़र्स (Total Users):** `{$totalUsers}`\n";
            $reply .= "• **सिस्टम स्टेटस:** 🟢 Active & Running\n\n";
            $reply .= "**हाल ही में जुड़े 5 मर्चेंट्स:**\n";
            foreach ($recentMerchants as $m) {
                $name = trim(($m->firstname ?? '') . ' ' . ($m->lastname ?? '')) ?: 'Merchant #' . $m->id;
                $reply .= "1. **{$name}** (📞 {$m->phone}) - *{$m->created_at}*\n";
            }

            $actions = [];
            if ($role === 'admin') {
                $actions[] = ['label' => 'सभी मर्चेंट्स देखें', 'url' => route('admin.users', ['type' => 'merchant']), 'icon' => 'users'];
            }

            return [
                'reply' => $reply,
                'suggestions' => ['Active Customers kitne hain?', 'System me total udhar kitna hai?', 'Mera balance batao'],
                'actions' => $actions
            ];
        }

        // 2. Merchant Khata, Balance & Udhar Dashboard Query
        if (str_contains($q, 'balance') || str_contains($q, 'khata') || str_contains($q, 'mera udhar') || str_contains($q, 'dashboard') || str_contains($q, 'hisaab')) {
            if ($user && ($user->type === 'merchant' || $user->role === 'merchant')) {
                $mId = $user->id;
                $shopName = $user->shop_name ?? ($user->business_name ?? 'आपकी दुकान');
                
                $totalGiven = 0;
                $totalReceived = 0;
                $customerCount = 0;

                if (Schema::hasTable('udhar_customers')) {
                    $customerCount = DB::table('udhar_customers')->where('merchant_id', $mId)->count();
                }

                if (Schema::hasTable('udhars')) {
                    $totalGiven = DB::table('udhars')->where('merchant_id', $mId)->where('type', 'give')->sum('amount');
                    $totalReceived = DB::table('udhars')->where('merchant_id', $mId)->where('type', 'got')->sum('amount');
                }

                $pending = $totalGiven - $totalReceived;

                $reply = "🏪 **{$shopName} — आपका खाता सारांश:**\n\n";
                $reply .= "• **कुल दिया उधार (Credit Given):** ₹" . number_format($totalGiven, 2) . "\n";
                $reply .= "• **कुल जमा / वसूली (Payment Received):** ₹" . number_format($totalReceived, 2) . "\n";
                $reply .= "• **बाक़ी वसूली (Pending Balance):** ₹" . number_format(max(0, $pending), 2) . "\n";
                $reply .= "• **खाते में कुल ग्राहक (Customers):** {$customerCount}\n\n";
                $reply .= "💡 *सुझाव:* किसी भी ग्राहक को पेमेंट रिमाइंडर भेजने के लिए नीचे दिए गए बटन पर क्लिक करें।";

                return [
                    'reply' => $reply,
                    'suggestions' => ['Naya customer kaise jodein?', 'WhatsApp payment reminder template', '28 days rules'],
                    'actions' => [
                        ['label' => 'खाता डैशबोर्ड खोलें', 'url' => url('/user/udhar/dashboard'), 'icon' => 'dashboard'],
                        ['label' => 'ग्राहक सूची देखें', 'url' => url('/user/udhar/customers'), 'icon' => 'list']
                    ]
                ];
            } else {
                $reply = "ℹ️ **UdharCard Merchant Khata Overview:**\n\n";
                $reply .= "UdharCard मर्चेंट पोर्टल में आप अपनी दुकान का सम्पूर्ण उधार-जमा (Khata Ledger) डिजिटल तरीके से प्रबंधित कर सकते हैं।\n\n";
                $reply .= "• 28 दिन का ब्याज-मुक्त उधार\n• ऑटोमैटिक व्हाट्सएप पेमेंट रिमाइंडर\n• सुरक्षित क्लाउड बैकअप और QR कोड कलेक्शन\n\n";
                $reply .= "अगर आप मर्चेंट हैं, तो कृपया अपने अकाउंट में लॉगिन करें।";

                return [
                    'reply' => $reply,
                    'suggestions' => ['Merchant login kaise karein?', '28 din ke niyam kya hain?'],
                    'actions' => [
                        ['label' => 'मर्चेंट लॉगिन', 'url' => url('/login'), 'icon' => 'login']
                    ]
                ];
            }
        }

        // 3. Customer Add / Party Management
        if (str_contains($q, 'customer') && (str_contains($q, 'add') || str_contains($q, 'naya') || str_contains($q, 'kaise') || str_contains($q, 'jode') || str_contains($q, 'party'))) {
            $reply = "👥 **नया ग्राहक / पार्टी जोड़ने की प्रक्रिया:**\n\n";
            $reply .= "1. **ग्राहक का नाम** और **10-अंकों का मोबाइल नंबर** दर्ज करें।\n";
            $reply .= "2. **पार्टी का प्रकार** चुनें (Customer, Dealer, Wholesaler, Supplier).\n";
            $reply .= "3. यदि पहले से कोई पुराना बाक़ी हिसाब है तो **Opening Balance** दर्ज करें।\n";
            $reply .= "4. **'Save Customer'** बटन दबाते ही ग्राहक आपके खाते में तुरंत जुड़ जाएगा!\n\n";
            $reply .= "💡 *मर्चेंट मोबाइल ऐप या वेब पैनल दोनों से सीधे ग्राहक जोड़ा जा सकता है।*";

            $actions = [];
            if ($user) {
                $actions[] = ['label' => 'नया ग्राहक जोड़ें', 'url' => url('/user/udhar/customers/create'), 'icon' => 'plus'];
            }

            return [
                'reply' => $reply,
                'suggestions' => ['Udhar entry kaise dalein?', 'WhatsApp reminder kaise bhejein?'],
                'actions' => $actions
            ];
        }

        // 4. Udhar / Jama Entry Process
        if (str_contains($q, 'entry') || str_contains($q, 'jama') || str_contains($q, 'udhar diya') || str_contains($q, 'credit')) {
            $reply = "📒 **उधार (Credit) या जमा (Payment Received) की एंट्री कैसे करें:**\n\n";
            $reply .= "• **उधार दिया (You Gave / Credit):**\n";
            $reply .= "  1. ग्राहक के नाम पर टैप करें।\n";
            $reply .= "  2. लाल बटन **'उधार दिया (You Gave)'** पर क्लिक करें।\n";
            $reply .= "  3. राशि (Amount), सामान का विवरण (Item Details) और बिल की फोटो जोड़ें।\n";
            $reply .= "  4. 'Save' करें — ग्राहक को तुरंत SMS/Notification चला जाएगा।\n\n";
            $reply .= "• **रुपये मिले (You Got / Jama):**\n";
            $reply .= "  1. हरे बटन **'रुपये मिले (You Got)'** पर क्लिक करें।\n";
            $reply .= "  2. प्राप्त राशि और माध्यम (Cash / Online UPI) दर्ज कर सेव करें।";

            return [
                'reply' => $reply,
                'suggestions' => ['Bill due date kaise set karein?', 'Mera balance kitna hai?'],
                'actions' => [
                    ['label' => 'ग्राहक खाता खोलें', 'url' => url('/user/udhar/customers'), 'icon' => 'book']
                ]
            ];
        }

        // 5. 28 Days Interest-Free Rules & Credit Limits
        if (str_contains($q, '28') || str_contains($q, 'interest') || str_contains($q, 'byaj') || str_contains($q, 'rule') || str_contains($q, 'limit') || str_contains($q, 'niyam')) {
            $reply = "💳 **UdharCard 28-दिन ब्याज-मुक्त नियम और क्रेडिट सीमा:**\n\n";
            $reply .= "• **ब्याज-मुक्त अवधि:** खरीद की तारीख से पूरे 28 दिनों तक **0% ब्याज (Zero Interest)** रहता है।\n";
            $reply .= "• **क्रेडिट लिमिट:** ₹5,000 से लेकर ₹5,00,000 तक (उपभोक्ता के प्रोफाइल और स्कोर के आधार पर)।\n";
            $reply .= "• **पारदर्शिता:** कोई छिपा हुआ शुल्क या वार्षिक शुल्क नहीं है।\n";
            $reply .= "• **सुरक्षा:** 100% RBI कंप्लेंट डिजिटल क्रेडिट मॉडल।\n\n";
            $reply .= "समय पर भुगतान करने पर ग्राहक की क्रेडिट लिमिट स्वतः बढ़ा दी जाती है।";

            return [
                'reply' => $reply,
                'suggestions' => ['Total kitne merchants hain?', 'Payment reminder bhejne ka template'],
                'actions' => [
                    ['label' => 'नियम व शर्तें पढ़ें', 'url' => url('/terms'), 'icon' => 'file-text']
                ]
            ];
        }

        // 6. WhatsApp Payment Reminder Template
        if (str_contains($q, 'reminder') || str_contains($q, 'whatsapp') || str_contains($q, 'vasooli') || str_contains($q, 'message')) {
            $shopName = ($user && !empty($user->shop_name)) ? $user->shop_name : "UdharCard Partner Store";
            
            $template = "प्रिय ग्राहक, {$shopName} से आपके खाते में ₹[AMOUNT] का भुगतान बाक़ी है। कृपया समय पर भुगतान करके अपनी ब्याज-मुक्त क्रेडिट सुविधा जारी रखें। UPI से भुगतान करने के लिए इस लिंक पर क्लिक करें: https://pay.udharcard.shop/pay/[QR_CODE] - धन्यवाद!";

            $reply = "🔔 **व्हाट्सएप पेमेंट रिमाइंडर टेम्पलेट:**\n\n";
            $reply .= "```text\n{$template}\n```\n\n";
            $reply .= "💡 *मर्चेंट ऐप या पोर्टल में आप ग्राहक के खाते के अंदर 'Send WhatsApp Reminder' बटन पर क्लिक करके 1-क्लिक में यह मैसेज सीधे ग्राहक के व्हाट्सएप पर भेज सकते हैं।*";

            return [
                'reply' => $reply,
                'suggestions' => ['Mera dashboard balance', 'Naya customer add karein'],
                'actions' => [
                    ['label' => 'ग्राहक सूची पर जाएं', 'url' => url('/user/udhar/customers'), 'icon' => 'send']
                ]
            ];
        }

        // 7. MCP / AI Integration Guide
        if (str_contains($q, 'mcp') || str_contains($q, 'claude') || str_contains($q, 'antigravity') || str_contains($q, 'ai tool') || str_contains($q, 'api')) {
            $reply = "⚡ **UdharCard MCP (Model Context Protocol) AI Assistant Studio:**\n\n";
            $reply .= "UdharCard MCP सर्वर की मदद से आप **Google Antigravity IDE**, **Claude Desktop** या **Cursor** में सीधे अपनी दुकान का खाता बोलकर या लिखकर संभाल सकते हैं!\n\n";
            $reply .= "• **Live MCP Endpoint:** `https://pay.udharcard.shop/api`\n";
            $reply .= "• **उपलब्ध टूल्स:** `login_merchant`, `get_merchant_dashboard`, `list_customers`, `add_customer`, `add_ledger_entry`, `send_payment_reminder`\n\n";
            $reply .= "विस्तृत गाइड और 1-क्लिक कॉन्फिग कोड देखने के लिए नीचे दिए गए बटन पर क्लिक करें।";

            return [
                'reply' => $reply,
                'suggestions' => ['Total kitne merchants hain?', 'Mera balance batao'],
                'actions' => [
                    ['label' => 'संपूर्ण MCP गाइड खोलें', 'url' => url('/merchant/mcp-guide'), 'icon' => 'external-link']
                ]
            ];
        }

        // 8. General / Fallback Conversational Response using Gemini 3.8 Live if available
        $apiKey = env('GEMINI_API_KEY');
        if (!empty($apiKey)) {
            $geminiPrompt = "You are the intelligent AI Assistant for UdharCard (pay.udharcard.shop), an Indian fintech credit ledger platform.\n" .
                "User role: {$role}.\n" .
                "Answer the user's question helpfully in polite Roman Hindi (Hinglish) or English: \"{$query}\"";
            $geminiRes = $this->callGeminiApi($apiKey, env('GEMINI_LIVE_MODEL', 'gemini-3.8-flash'), $geminiPrompt, false, 0.3);
            if ($geminiRes['success'] && !empty($geminiRes['text'])) {
                return [
                    'reply' => trim($geminiRes['text']),
                    'suggestions' => $this->getDefaultSuggestions($role),
                    'actions' => []
                ];
            }
        }

        $reply = "नमस्ते! मैं **UdharCard AI Assistant (Gemini 3.8 Live)** हूँ।\n\n";
        $reply .= "मैं आपकी दुकान के खाते, उधार-जमा, ग्राहकों, पेमेंट रिमाइंडर्स और सिस्टम रिपोर्ट्स में मदद कर सकता हूँ।\n\n";
        $reply .= "आप मुझसे निम्नलिखित प्रश्न पूछ सकते हैं:\n";
        $reply .= "• *'Total kitne merchants register hain?'*\n";
        $reply .= "• *'Mera balance aur khata summary dikhao'*\n";
        $reply .= "• *'Naya customer kaise add karein?'*\n";
        $reply .= "• *'WhatsApp payment reminder message banao'*\n";
        $reply .= "• *'28 din ke interest-free niyam kya hain?'*\n";
        $reply .= "• *'MCP server se AI kaise connect karein?'*";

        return [
            'reply' => $reply,
            'suggestions' => $this->getDefaultSuggestions($role),
            'actions' => []
        ];
    }

    /**
     * Dedicated Voice Khata Entry Parser using Google Gemini 3.8 Live & 3.8 Live Extended Thinking
     */
    public function voiceParse(Request $request)
    {
        $speechText = trim((string)$request->input('speech_text', $request->input('text', $request->input('query', ''))));
        if (empty($speechText)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Please provide speech_text to parse.',
            ], 422);
        }

        $mode = $request->input('mode', 'live');
        $useThinking = in_array(strtolower($mode), ['thinking', 'extended_thinking', 'gemini38extendedthinking']);

        $apiKey = env('GEMINI_API_KEY');
        if (empty($apiKey)) {
            return response()->json([
                'status' => 'error',
                'message' => 'GEMINI_API_KEY is not configured on the server.',
                'fallback' => $this->fallbackLocalParse($speechText),
            ], 500);
        }

        $modelName = $useThinking 
            ? env('GEMINI_THINKING_MODEL', 'gemini-3.8-flash')
            : env('GEMINI_LIVE_MODEL', 'gemini-3.8-flash');

        if (str_contains($modelName, '2.0') || str_contains($modelName, '2.5')) {
            $modelName = 'gemini-3.8-flash';
        }

        $prompt = $useThinking 
            ? $this->buildThinkingPrompt($speechText)
            : $this->buildLivePrompt($speechText);

        $result = $this->callGeminiApi($apiKey, $modelName, $prompt, true, $useThinking ? 0.2 : 0.1);

        if (!$result['success']) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gemini API call failed: ' . ($result['error'] ?? 'Unknown error'),
                'fallback' => $this->fallbackLocalParse($speechText),
            ], 502);
        }

        $parsedJson = json_decode($result['text'], true);
        if (!$parsedJson) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to decode Gemini JSON output.',
                'raw' => $result['text'],
                'fallback' => $this->fallbackLocalParse($speechText),
            ], 502);
        }

        return response()->json([
            'status' => 'success',
            'model' => $modelName,
            'engine' => $useThinking ? 'Gemini 3.8 Live Extended Thinking' : 'Gemini 3.8 Live',
            'data' => $parsedJson,
        ]);
    }

    /**
     * Build Prompt for Gemini 3.8 Live (Fast Conversational Mode)
     */
    protected function buildLivePrompt(string $speechText): string
    {
        return <<<PROMPT
You are a real-time Gemini 3.8 Live AI assistant for an Indian merchant ledger app (UdharCard).
The merchant speaks in Hindi, Hinglish, or English.
Analyze the user's speech and extract information into strictly valid JSON with ultra-low latency.

Categories of speech:
1. "transaction": Merchant giving credit or receiving payment.
   Examples:
   - "Ramesh ko 500 rupaye udhar diya" -> action: "transaction", name: "Ramesh", amount: 500, type: "Given", category: "UDHAR"
   - "Suresh se 1200 mile" -> action: "transaction", name: "Suresh", amount: 1200, type: "Received", category: "COLLECTION"
2. "purchase_order": Stock/grocery items that are finished and need to be ordered.
   Example: "Doodh aur bread khatam ho gaya mangwana hai" -> action: "purchase_order", purchase_items: ["Doodh", "Bread"]
3. "balance_query": Checking balance of customer or total.
   Example: "Ramesh ka kitna baki hai?" -> action: "balance_query", name: "Ramesh"
4. "itemized_bill": Items with quantity and price.
   Example: "2 kg cheeni 40 rupaye aur 1 packet surf 60 rupaye" -> action: "itemized_bill", bill_items: [{"title": "Cheeni", "quantity": 2, "unit": "kg", "unitPrice": 40, "totalPrice": 80}]
5. "help": Greeting or asking how to use.

Output JSON structure:
{
  "action": "transaction" | "purchase_order" | "balance_query" | "itemized_bill" | "help",
  "name": "Customer Name or empty string",
  "amount": number,
  "type": "Given" | "Received",
  "category": "UDHAR" | "COLLECTION" | "PURCHASE" | "BILL",
  "purchase_items": ["item 1", "item 2"],
  "bill_items": [{"title": "Item", "quantity": 1, "unit": "kg", "unitPrice": 50, "totalPrice": 50}],
  "remarks": "short remarks if any",
  "reply": "Friendly short reply in Roman Hinglish to speak back to the merchant"
}

Merchant speech: "{$speechText}"
PROMPT;
    }

    /**
     * Build Prompt for Gemini 3.8 Live Extended Thinking (Deep Arithmetic & Calculation Mode)
     */
    protected function buildThinkingPrompt(string $speechText): string
    {
        return <<<PROMPT
You are an advanced retail accounting AI with Gemini 3.8 Live Extended Thinking capabilities for an Indian merchant ledger app (UdharCard).
The merchant speaks in Hindi, Hinglish, or English.
Carefully perform step-by-step arithmetic reasoning and ledger disambiguation before generating JSON.

Extended Thinking Reasoning Guidelines:
1. Multi-Item Calculations:
   - If user says item quantities and rates (e.g., "5 kg chini 42 rupaye, aur 2 packet tel 120 rupaye"), compute:
     chini = 5 * 42 = 210
     tel = 2 * 120 = 240
     total = 450
2. Split Payments & Net Credit:
   - If user gave partial cash (e.g., "total bill 450 me se 200 cash diya, baki udhar"), compute net credit = 450 - 200 = 250.
   - Set type: "Given", amount: 250, remarks: "Bill: ₹450, Cash Paid: ₹200, Net Udhar: ₹250".
3. Previous Balance Settlement:
   - If user settled past balance (e.g., "purana 300 baki tha usme se 200 diya"), compute net payment received = 200, type: "Received".
4. Purchase Orders:
   - If user lists finished grocery items ("ye khatam ho gaya"), categorize as "purchase_order".

Output JSON structure:
{
  "action": "transaction" | "purchase_order" | "balance_query" | "itemized_bill" | "help",
  "name": "Customer Name or empty string",
  "amount": computed_final_number,
  "type": "Given" | "Received",
  "category": "UDHAR" | "COLLECTION" | "PURCHASE" | "BILL",
  "purchase_items": ["item 1", "item 2"],
  "bill_items": [{"title": "Item", "quantity": 1, "unit": "kg", "unitPrice": 50, "totalPrice": 50}],
  "remarks": "detailed calculation remarks",
  "reply": "Clear, friendly Roman Hinglish explanation of the calculation and result to speak back to the merchant"
}

Merchant speech: "{$speechText}"
PROMPT;
    }

    /**
     * Call Google Gemini API directly over cURL
     */
    protected function callGeminiApi(string $apiKey, string $model, string $prompt, bool $jsonMime = true, float $temperature = 0.1): array
    {
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey);

        $payload = [
            'contents' => [
                [
                    'parts' => [
                        ['text' => $prompt]
                    ]
                ]
            ],
            'generationConfig' => [
                'temperature' => $temperature,
            ]
        ];

        if ($jsonMime) {
            $payload['generationConfig']['responseMimeType'] = 'application/json';
        }

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        curl_setopt($ch, CURLOPT_TIMEOUT, 12);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($curlError || $httpCode < 200 || $httpCode >= 300) {
            return [
                'success' => false,
                'error' => "HTTP {$httpCode}: " . ($response ?: $curlError),
            ];
        }

        $data = json_decode($response, true);
        $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';

        return [
            'success' => !empty($text),
            'text' => $text,
            'model' => $model,
        ];
    }

    /**
     * Fallback Kirana NLP parser when external API is unreachable
     */
    protected function fallbackLocalParse(string $text): array
    {
        $lower = mb_strtolower($text, 'UTF-8');
        $type = (str_contains($lower, 'mile') || str_contains($lower, 'mila') || str_contains($lower, 'jama')) ? 'Received' : 'Given';
        
        preg_match('/(\d+(?:\.\d+)?)/', $lower, $amtMatches);
        $amount = isset($amtMatches[1]) ? (float)$amtMatches[1] : 0.0;

        $clean = preg_replace('/\b(\d+|rupaye|rupees|rs|udhar|udhaar|ko|se|ne|diya|mile|mila|jama)\b/iu', '', $lower);
        $clean = trim(preg_replace('/\s+/', ' ', $clean));
        $name = !empty($clean) ? ucwords($clean) : 'Customer';

        return [
            'action' => $amount > 0 ? 'transaction' : 'help',
            'name' => $name,
            'amount' => $amount,
            'type' => $type,
            'category' => $type === 'Received' ? 'COLLECTION' : 'UDHAR',
            'remarks' => 'Local fallback parse',
            'reply' => $type === 'Given' 
                ? "{$name} ko ₹{$amount} udhar darj kiya gaya."
                : "{$name} se ₹{$amount} jama kiye gaye.",
        ];
    }

    /**
     * Role-specific prompt suggestions.
     */
    protected function getDefaultSuggestions($role)
    {
        if ($role === 'admin') {
            return [
                'Total kitne merchants register hain?',
                'Active users aur merchants count',
                'System khata summary',
                'MCP Guide Page'
            ];
        } elseif ($role === 'merchant') {
            return [
                'Mera balance aur khata summary dikhao',
                'Naya customer kaise jodein?',
                'WhatsApp payment reminder template',
                '28 din ke interest-free niyam'
            ];
        } else {
            return [
                'UdharCard kya hai aur kaise kaam karta hai?',
                '28 din ka interest free credit rule',
                'Total kitne merchants register hain?',
                'Merchant app download link'
            ];
        }
    }
}
