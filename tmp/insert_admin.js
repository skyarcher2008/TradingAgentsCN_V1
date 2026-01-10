db.users.insertOne({
  username: 'admin',
  email: 'admin@tradingagents.cn',
  hashed_password: '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
  is_active: true,
  is_verified: true,
  is_admin: true,
  created_at: new Date(),
  updated_at: new Date(),
  last_login: null,
  preferences: {
    default_market: 'A股',
    default_depth: '深度',
    ui_theme: 'light',
    language: 'zh-CN',
    notifications_enabled: true,
    email_notifications: false
  },
  daily_quota: 10000,
  concurrent_limit: 10,
  total_analyses: 0,
  successful_analyses: 0,
  failed_analyses: 0,
  favorite_stocks: []
});

printjson(db.users.findOne({username: 'admin'}));
