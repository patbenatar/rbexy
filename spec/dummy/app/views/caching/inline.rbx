<h1>Hello view template</h1>
{CacheHeartbeat.beat1}

<Rbexy.Cache key="outer">
  <h2>Hello outer cache</h2>

  <Rbexy.Cache key="inner">
    <h3>Hello inner cache</h3>
    {CacheHeartbeat.beat2}
  </Rbexy.Cache>
</Rbexy.Cache>
