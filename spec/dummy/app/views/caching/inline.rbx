<h1>Hello view template</h1>

<Rbexy.Cache key="outer">
  <h2>Hello outer cache</h2>
  {Thread.current[:cache_misses] += 1}
</Rbexy.Cache>
