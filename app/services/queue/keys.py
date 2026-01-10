"""
队列服务用到的 Redis 键名与配置常量（集中定义）
"""

# Redis键名常量
READY_LIST = "qa:ready"

TASK_PREFIX = "qa:task:"
BATCH_PREFIX = "qa:batch:"
SET_PROCESSING = "qa:processing"
SET_COMPLETED = "qa:completed"
SET_FAILED = "qa:failed"
BATCH_TASKS_PREFIX = "qa:batch_tasks:"

# 并发控制相关
USER_PROCESSING_PREFIX = "qa:user_processing:"
GLOBAL_CONCURRENT_KEY = "qa:global_concurrent"
VISIBILITY_TIMEOUT_PREFIX = "qa:visibility:"

# 配置常量 - 开源版限制 (NAS低功耗优化版)
DEFAULT_USER_CONCURRENT_LIMIT = 3  # 降低单用户并发
GLOBAL_CONCURRENT_LIMIT = 3        # 降低全局并发，适应N150/8G硬件
VISIBILITY_TIMEOUT_SECONDS = 300   # 5分钟

