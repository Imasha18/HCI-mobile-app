const roles = Object.freeze(['customer', 'cook', 'rider', 'admin']);
const orderStatuses = Object.freeze(['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivered', 'cancelled']);

module.exports = { roles, orderStatuses };
