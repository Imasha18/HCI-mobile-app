async function createPaymentIntent({ amount, orderId }) {
  return { amount, orderId, status: 'pending', provider: 'placeholder' };
}

module.exports = { createPaymentIntent };
