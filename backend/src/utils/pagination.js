function parsePagination(query, defaultLimit = 10) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || defaultLimit));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
}

function buildPaginationMeta(page, limit, total, itemsCount) {
  return {
    page,
    limit,
    total,
    hasNextPage: (page - 1) * limit + itemsCount < total,
  };
}

module.exports = { parsePagination, buildPaginationMeta };
