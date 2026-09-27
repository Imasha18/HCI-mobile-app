const Order = require('../models/Order');

async function findCustomerOrders(customerId) {
  return Order.find({ customer: customerId }).populate('items.meal');
}

module.exports = { findCustomerOrders };
