const functions = require("firebase-functions");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");

admin.initializeApp();

// Mendefinisikan secrets yang akan digunakan oleh fungsi
const MIDTRANS_SERVER_KEY = functions.config().midtrans.server_key;
const MIDTRANS_CLIENT_KEY = functions.config().midtrans.client_key;


// Inisialisasi Midtrans Snap API
const snap = new midtransClient.Snap({
  isProduction: false, // Set ke true saat Go-Live
  serverKey: MIDTRANS_SERVER_KEY,
  clientKey: MIDTRANS_CLIENT_KEY,
});

/**
 * Cloud Function untuk membuat transaksi Midtrans.
 * @param {object} data - Data yang dikirim dari client.
 * @param {object} context - Konteks otentikasi.
 * @return {Promise<{token: string}>} Token transaksi dari Midtrans.
 */
exports.createMidtransTransaction = functions.https.onCall(async (data,
    context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  const orderId = data.orderId;
  const amount = data.amount;
  const customerName = data.customerName || "Customer";
  const customerEmail = context.auth.token.email || data.customerEmail;

  if (!orderId || !amount) {
    throw new functions.https.https.HttpsError(
        "invalid-argument",
        "The function must be called with 'orderId' and 'amount'.",
    );
  }

  const parameter = {
    "transaction_details": {
      "order_id": orderId,
      "gross_amount": amount,
    },
    "customer_details": {
      "first_name": customerName,
      "email": customerEmail,
    },
  };

  try {
    const transaction = await snap.createTransaction(parameter);
    const transactionToken = transaction.token;
    console.log("Midtrans transaction token created:", transactionToken);
    return {token: transactionToken};
  } catch (e) {
    console.error("Error creating Midtrans transaction:", e);
    throw new functions.https.HttpsError(
        "internal",
        "Failed to create transaction with Midtrans.",
        e.message,
    );
  }
});

