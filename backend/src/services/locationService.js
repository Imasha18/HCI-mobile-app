async function getDeliveryEstimate(origin, destination) {
  return { origin, destination, minutes: null, provider: 'not-configured' };
}

module.exports = { getDeliveryEstimate };
