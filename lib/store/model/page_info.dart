class PageInfo<K> {
  PageInfo({
    this.hasNext = false,
    this.hasPrevious = false,
    this.startCursor,
    this.endCursor,
  });

  bool hasNext;

  bool hasPrevious;

  K? startCursor;

  K? endCursor;
}
