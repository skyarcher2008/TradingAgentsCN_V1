<template>
  <div class="user-profile" :class="{ collapsed: appStore.sidebarCollapsed }">
    <div class="profile-info">
      <el-avatar :size="32" :src="userAvatar">
        <el-icon><User /></el-icon>
      </el-avatar>
      <div v-if="!appStore.sidebarCollapsed" class="user-info">
        <div class="username">Admin</div>
        <div class="user-role">管理员</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { User } from '@element-plus/icons-vue'

const appStore = useAppStore()

// 用户头像：由于单机版固定为Admin，这里可以简化
const userAvatar = undefined

</script>

<style lang="scss" scoped>
.user-profile {
  padding: 12px;

  &.collapsed {
    padding: 8px;
    text-align: center;
  }

  .profile-info {
    display: flex;
    align-items: center;
    gap: 12px;
    cursor: pointer;
    padding: 8px;
    border-radius: 6px;
    transition: background-color 0.3s ease;

    &:hover {
      background-color: var(--el-fill-color-lighter);
    }

    .user-info {
      flex: 1;
      min-width: 0;

      .username {
        font-size: 14px;
        font-weight: 500;
        color: var(--el-text-color-primary);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .user-role {
        font-size: 12px;
        color: var(--el-text-color-placeholder);
      }
    }
  }
}
</style>
