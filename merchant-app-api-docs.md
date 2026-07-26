# UdharCard Merchant App - API Integration Documentation

This document specifies the REST API endpoints developed in the backend for the **Udhar Ledger System** and how they integrate with the mobile app.

---

## 1. Authentication Configuration

All authenticated requests must include the Sanctum bearer token in the headers:
- Header: `Authorization: Bearer <token>`
- Fallback/Testing Header: `X-Merchant-Id: <id>` (used by backend when token is not present during dev testing)

---

## 2. Customer Management Endpoints

### 2.1 Get Customers List
Retreives all customers mapped to the authenticated merchant.

* **URL:** `/api/merchant/users`
* **Method:** `GET`
* **Headers:** 
  * `Authorization: Bearer <token>`
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "data": {
      "contacts": [
        {
          "id": 1,
          "name": "Ramesh Kumar",
          "phone": "+919876543210",
          "email": "ramesh@example.com",
          "opening_balance": "0.00",
          "outstanding_balance": "1500.00",
          "credit_limit": "5000.00"
        }
      ]
    }
  }
  ```

### 2.2 Add New Customer
Creates a new customer under the authenticated merchant's ledger.

* **URL:** `/api/merchant/users/add`
* **Method:** `POST`
* **Headers:**
  * `Authorization: Bearer <token>`
  * `Content-Type: application/json`
* **Request Body:**
  ```json
  {
    "name": "John Doe",
    "phone": "+919999999999",
    "email": "john@example.com",
    "credit_limit": 5000.00,
    "opening_balance": 0.00
  }
  ```
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Customer created successfully.",
    "data": {
      "merchant_id": 1,
      "name": "John Doe",
      "phone": "+919999999999",
      "email": "john@example.com",
      "credit_limit": 5000,
      "opening_balance": 0,
      "outstanding_balance": 0,
      "id": 10
    }
  }
  ```
* **Error Response (400 Bad Request / 422 Unprocessable Entity):**
  ```json
  {
    "status": "error",
    "message": "A customer with this phone number already exists."
  }
  ```

### 2.3 Delete Customer Account
Deletes a specific customer account and their ledger relationship.

* **URL:** `/api/merchant/users/delete/{id}`
* **Method:** `DELETE`
* **Headers:**
  * `Authorization: Bearer <token>`
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Customer account deleted successfully."
  }
  ```
* **Error Response (404 Not Found):**
  ```json
  {
    "status": "error",
    "message": "Customer not found."
  }
  ```

---

## 3. Udhar Ledger & Transactions

### 3.1 Record Udhar (Credit / Debit)
Records a new credit transaction (`given`) or payment collection (`received`). If the type is `given`, it increases the outstanding balance. If `received`, it decreases the balance. Enforces the customer's credit limit on `given` transactions.

* **URL:** `/api/merchant/udhar`
* **Method:** `POST`
* **Headers:**
  * `Authorization: Bearer <token>`
  * `Content-Type: application/json`
* **Request Body:**
  ```json
  {
    "email_or_phone": "john@example.com",
    "amount": 250.00,
    "type": "given", 
    "remarks": "purchase of grocery item",
    "due_date": "2026-07-20",
    "payment_method": "cash"
  }
  ```
  *Note: `type` must be either `given` (credit/Udhar) or `received` (debit/payment).*
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Ledger transaction recorded successfully.",
    "data": {
      "transaction_id": 45,
      "outstanding_balance": 250.00
    }
  }
  ```
* **Error Response (400 Bad Request - Limit Exceeded):**
  ```json
  {
    "status": "error",
    "message": "Transaction declined. This exceeds the customer's credit limit of ₹5,000.00"
  }
  ```

### 3.2 Get Customer Ledger Details & History
Retrieves details of a specific customer along with their complete chronological transaction ledger.

* **URL:** `/api/merchant/ledger/{customer_id}`
* **Method:** `GET`
* **Headers:**
  * `Authorization: Bearer <token>`
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "data": {
      "customer_name": "Ramesh Kumar",
      "outstanding_balance": 1500,
      "credit_limit": 5000,
      "transactions": [
        {
          "id": 101,
          "amount": 2500,
          "type": "given",
          "remarks": "Grocery purchase (rice, oil, dal)",
          "created_at": "2026-06-15 10:30:00",
          "due_date": "2026-07-15"
        },
        {
          "id": 102,
          "amount": 1000,
          "type": "received",
          "remarks": "Paid via cash",
          "created_at": "2026-06-18 14:15:00",
          "due_date": null
        }
      ]
    }
  }
  ```

---

## 4. Payment Gateway Webhooks

### 4.1 Process Gateway Webhook (Razorpay/PhonePe)
Processes inbound successful payments from online QR scans or customer links, dynamically updating the merchant's customer outstanding balance.

* **URL:** `/api/payment/webhook`
* **Method:** `POST`
* **Headers:**
  * `X-Razorpay-Signature`: `<signature_key>`
* **Success Response (200 OK):**
  ```json
  {
    "status": "success",
    "message": "Ledger updated successfully"
  }
  ```
