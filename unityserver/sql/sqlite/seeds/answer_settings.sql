-- BEGIN GENERATED UNITY ANSWER SETTINGS SEED
INSERT INTO answer_settings (id,daily_attempt_limit,fallback_reward_type,fallback_reward_amount) VALUES
(1,1,60000,1000)
ON CONFLICT(id) DO UPDATE SET
  daily_attempt_limit=excluded.daily_attempt_limit,
  fallback_reward_type=excluded.fallback_reward_type,
  fallback_reward_amount=excluded.fallback_reward_amount;
-- END GENERATED UNITY ANSWER SETTINGS SEED
