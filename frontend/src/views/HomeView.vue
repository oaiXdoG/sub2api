<template>
  <!-- Custom Home Content: Full Page Mode -->
  <div v-if="homeContent" class="min-h-screen">
    <iframe
      v-if="isHomeContentUrl"
      :src="homeContent.trim()"
      class="h-screen w-full border-0"
      allowfullscreen
    ></iframe>
    <!-- HTML mode - SECURITY: homeContent is admin-only setting, XSS risk is acceptable -->
    <div v-else v-html="homeContent"></div>
  </div>

  <!-- Default Home Page -->
  <div
    v-else
    class="relative flex min-h-screen flex-col overflow-hidden bg-[#f7f2ec] text-[#201d19] dark:bg-[#11100e] dark:text-[#f4efe8]"
  >
    <div
      class="pointer-events-none absolute inset-0 bg-[linear-gradient(180deg,rgba(223,138,108,0.14),rgba(17,16,14,0)_42%),linear-gradient(90deg,rgba(223,138,108,0.06)_1px,transparent_1px),linear-gradient(180deg,rgba(223,138,108,0.06)_1px,transparent_1px)] bg-[size:100%_100%,72px_72px,72px_72px]"
    ></div>

    <header class="relative z-20 border-b border-[#d7c9b7]/70 bg-[#f7f2ec]/85 px-6 py-4 backdrop-blur dark:border-[#2f2a25] dark:bg-[#11100e]/85">
      <nav class="mx-auto flex max-w-6xl items-center justify-between gap-4">
        <div class="flex min-w-0 items-center gap-3">
          <div class="h-10 w-10 shrink-0 overflow-hidden rounded-xl border border-[#e3d5c4] bg-white shadow-sm dark:border-[#3a332d] dark:bg-[#1c1915]">
            <img :src="siteLogo || '/logo.png'" alt="Logo" class="h-full w-full object-contain" />
          </div>
          <span class="truncate text-base font-semibold tracking-normal text-[#16130f] dark:text-white">
            {{ siteName }}
          </span>
        </div>

        <div class="flex items-center gap-2 sm:gap-3">
          <LocaleSwitcher />

          <a
            v-if="docUrl"
            :href="docUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="rounded-lg p-2 text-[#756b60] transition-colors hover:bg-[#efe3d6] hover:text-[#2b251f] dark:text-[#a8a09a] dark:hover:bg-[#23201c] dark:hover:text-white"
            :title="t('home.viewDocs')"
          >
            <Icon name="book" size="md" />
          </a>

          <button
            @click="toggleTheme"
            class="rounded-lg p-2 text-[#756b60] transition-colors hover:bg-[#efe3d6] hover:text-[#2b251f] dark:text-[#a8a09a] dark:hover:bg-[#23201c] dark:hover:text-white"
            :title="isDark ? t('home.switchToLight') : t('home.switchToDark')"
          >
            <Icon v-if="isDark" name="sun" size="md" />
            <Icon v-else name="moon" size="md" />
          </button>

          <router-link
            v-if="isAuthenticated"
            :to="dashboardPath"
            class="inline-flex items-center gap-1.5 rounded-full bg-[#201812] py-1 pl-1 pr-2.5 transition-colors hover:bg-[#3a2a21] dark:bg-[#df8a6c] dark:text-[#160f0b] dark:hover:bg-[#e79b80]"
          >
            <span
              class="flex h-5 w-5 items-center justify-center rounded-full bg-[#df8a6c] text-[10px] font-semibold text-white dark:bg-[#201812]"
            >
              {{ userInitial }}
            </span>
            <span class="text-xs font-medium text-white dark:text-[#160f0b]">{{ t('home.dashboard') }}</span>
            <Icon name="arrowRight" size="xs" class="text-white/70 dark:text-[#160f0b]/70" />
          </router-link>
          <router-link
            v-else
            to="/login"
            class="inline-flex items-center rounded-full bg-[#201812] px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-[#3a2a21] dark:bg-[#df8a6c] dark:text-[#160f0b] dark:hover:bg-[#e79b80]"
          >
            {{ t('home.login') }}
          </router-link>
        </div>
      </nav>
    </header>

    <main class="relative z-10 flex-1">
      <section class="mx-auto grid max-w-6xl gap-10 px-6 py-10 lg:grid-cols-[minmax(0,1.05fr)_minmax(360px,0.95fr)] lg:items-center lg:py-14">
        <div>
          <h1 class="mb-5 text-5xl font-bold tracking-normal text-[#16130f] dark:text-white md:text-6xl">
            {{ siteName }}
          </h1>
          <p class="mb-4 text-2xl font-semibold leading-tight text-[#3b3028] dark:text-[#efe6de] md:text-3xl">
            {{ t('home.heroTitle') }}
          </p>
          <p class="mb-8 max-w-2xl text-base leading-8 text-[#756b60] dark:text-[#aaa29a] md:text-lg">
            {{ t('home.heroDescription') }}
          </p>

          <div class="flex flex-col gap-3 sm:flex-row">
            <router-link
              :to="isAuthenticated ? dashboardPath : '/login'"
              class="inline-flex items-center justify-center rounded-full bg-[#df8a6c] px-7 py-3 text-sm font-semibold text-[#180f0a] shadow-lg shadow-[#df8a6c]/25 transition-colors hover:bg-[#e79b80]"
            >
              {{ isAuthenticated ? t('home.goToDashboard') : t('home.getStarted') }}
              <Icon name="arrowRight" size="sm" class="ml-2" :stroke-width="2" />
            </router-link>
          </div>
        </div>

        <div class="rounded-[28px] border border-[#d7c9b7]/80 bg-white/70 p-5 shadow-2xl shadow-[#4c2c1d]/10 backdrop-blur dark:border-[#3a332d] dark:bg-[#191612]/85 dark:shadow-black/35">
          <div class="mb-5 flex items-center justify-between gap-4">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.24em] text-[#9a6a54]">
                {{ t('home.statusPanel.eyebrow') }}
              </p>
              <h2 class="mt-2 text-xl font-semibold text-[#201812] dark:text-white">
                {{ t('home.statusPanel.title') }}
              </h2>
            </div>
            <span class="rounded-full border border-[#df8a6c]/35 px-3 py-1 text-xs font-semibold text-[#9a4c32] dark:text-[#f2a17f]">
              {{ t('home.statusPanel.state') }}
            </span>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div class="rounded-2xl border border-[#e1d4c2] bg-[#fbf7f1] p-4 dark:border-[#36302a] dark:bg-[#23201c]">
              <Icon name="shield" size="md" class="mb-4 text-[#df8a6c]" />
              <p class="text-sm font-semibold text-[#201812] dark:text-white">
                {{ t('home.statusPanel.stableTitle') }}
              </p>
              <p class="mt-2 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                {{ t('home.statusPanel.stableDesc') }}
              </p>
            </div>
            <div class="rounded-2xl border border-[#e1d4c2] bg-[#fbf7f1] p-4 dark:border-[#36302a] dark:bg-[#23201c]">
              <Icon name="grid" size="md" class="mb-4 text-[#df8a6c]" />
              <p class="text-sm font-semibold text-[#201812] dark:text-white">
                {{ t('home.statusPanel.choiceTitle') }}
              </p>
              <p class="mt-2 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                {{ t('home.statusPanel.choiceDesc') }}
              </p>
            </div>
            <div class="rounded-2xl border border-[#e1d4c2] bg-[#fbf7f1] p-4 dark:border-[#36302a] dark:bg-[#23201c]">
              <Icon name="chart" size="md" class="mb-4 text-[#df8a6c]" />
              <p class="text-sm font-semibold text-[#201812] dark:text-white">
                {{ t('home.statusPanel.usageTitle') }}
              </p>
              <p class="mt-2 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                {{ t('home.statusPanel.usageDesc') }}
              </p>
            </div>
            <div class="rounded-2xl border border-[#e1d4c2] bg-[#fbf7f1] p-4 dark:border-[#36302a] dark:bg-[#23201c]">
              <Icon name="clock" size="md" class="mb-4 text-[#df8a6c]" />
              <p class="text-sm font-semibold text-[#201812] dark:text-white">
                {{ t('home.statusPanel.resetTitle') }}
              </p>
              <p class="mt-2 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                {{ t('home.statusPanel.resetDesc') }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <section class="mx-auto max-w-6xl px-6 pb-16 pt-2">
        <div class="mb-7 max-w-2xl">
          <p class="mb-3 text-sm font-semibold uppercase tracking-[0.24em] text-[#9a6a54]">
            {{ t('home.featuresEyebrow') }}
          </p>
          <h2 class="text-3xl font-bold text-[#201812] dark:text-white">
            {{ t('home.featuresTitle') }}
          </h2>
          <p class="mt-3 text-base leading-7 text-[#756b60] dark:text-[#aaa29a]">
            {{ t('home.featuresDescription') }}
          </p>
        </div>

        <div class="grid gap-5 md:grid-cols-3">
          <article class="rounded-2xl border border-[#d7c9b7]/80 bg-white/70 p-6 dark:border-[#3a332d] dark:bg-[#191612]/85">
            <Icon name="bolt" size="lg" class="mb-5 text-[#df8a6c]" />
            <h3 class="text-lg font-semibold text-[#201812] dark:text-white">
              {{ t('home.features.fastTitle') }}
            </h3>
            <p class="mt-3 text-sm leading-7 text-[#756b60] dark:text-[#aaa29a]">
              {{ t('home.features.fastDesc') }}
            </p>
          </article>
          <article class="rounded-2xl border border-[#d7c9b7]/80 bg-white/70 p-6 dark:border-[#3a332d] dark:bg-[#191612]/85">
            <Icon name="shield" size="lg" class="mb-5 text-[#df8a6c]" />
            <h3 class="text-lg font-semibold text-[#201812] dark:text-white">
              {{ t('home.features.stableTitle') }}
            </h3>
            <p class="mt-3 text-sm leading-7 text-[#756b60] dark:text-[#aaa29a]">
              {{ t('home.features.stableDesc') }}
            </p>
          </article>
          <article class="rounded-2xl border border-[#d7c9b7]/80 bg-white/70 p-6 dark:border-[#3a332d] dark:bg-[#191612]/85">
            <Icon name="chart" size="lg" class="mb-5 text-[#df8a6c]" />
            <h3 class="text-lg font-semibold text-[#201812] dark:text-white">
              {{ t('home.features.controlTitle') }}
            </h3>
            <p class="mt-3 text-sm leading-7 text-[#756b60] dark:text-[#aaa29a]">
              {{ t('home.features.controlDesc') }}
            </p>
          </article>
        </div>
      </section>

      <section class="border-y border-[#d7c9b7]/70 bg-white/45 px-6 py-14 dark:border-[#2f2a25] dark:bg-[#171411]/80">
        <div class="mx-auto grid max-w-6xl gap-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-start">
          <div>
            <p class="mb-3 text-sm font-semibold uppercase tracking-[0.24em] text-[#9a6a54]">
              {{ t('home.scenarios.eyebrow') }}
            </p>
            <h2 class="text-3xl font-bold text-[#201812] dark:text-white">
              {{ t('home.scenarios.title') }}
            </h2>
            <p class="mt-3 text-base leading-7 text-[#756b60] dark:text-[#aaa29a]">
              {{ t('home.scenarios.description') }}
            </p>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div class="flex items-start gap-3 rounded-2xl border border-[#d7c9b7]/80 bg-[#f7f2ec]/70 p-4 dark:border-[#3a332d] dark:bg-[#201c18]">
              <Icon name="chat" size="md" class="mt-0.5 shrink-0 text-[#df8a6c]" />
              <div>
                <h3 class="text-sm font-semibold text-[#201812] dark:text-white">
                  {{ t('home.scenarios.chatTitle') }}
                </h3>
                <p class="mt-1 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                  {{ t('home.scenarios.chatDesc') }}
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3 rounded-2xl border border-[#d7c9b7]/80 bg-[#f7f2ec]/70 p-4 dark:border-[#3a332d] dark:bg-[#201c18]">
              <Icon name="cpu" size="md" class="mt-0.5 shrink-0 text-[#df8a6c]" />
              <div>
                <h3 class="text-sm font-semibold text-[#201812] dark:text-white">
                  {{ t('home.scenarios.codeTitle') }}
                </h3>
                <p class="mt-1 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                  {{ t('home.scenarios.codeDesc') }}
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3 rounded-2xl border border-[#d7c9b7]/80 bg-[#f7f2ec]/70 p-4 dark:border-[#3a332d] dark:bg-[#201c18]">
              <Icon name="document" size="md" class="mt-0.5 shrink-0 text-[#df8a6c]" />
              <div>
                <h3 class="text-sm font-semibold text-[#201812] dark:text-white">
                  {{ t('home.scenarios.contentTitle') }}
                </h3>
                <p class="mt-1 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                  {{ t('home.scenarios.contentDesc') }}
                </p>
              </div>
            </div>
            <div class="flex items-start gap-3 rounded-2xl border border-[#d7c9b7]/80 bg-[#f7f2ec]/70 p-4 dark:border-[#3a332d] dark:bg-[#201c18]">
              <Icon name="sparkles" size="md" class="mt-0.5 shrink-0 text-[#df8a6c]" />
              <div>
                <h3 class="text-sm font-semibold text-[#201812] dark:text-white">
                  {{ t('home.scenarios.choiceTitle') }}
                </h3>
                <p class="mt-1 text-sm leading-6 text-[#756b60] dark:text-[#aaa29a]">
                  {{ t('home.scenarios.choiceDesc') }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>

    <footer class="relative z-10 px-6 py-8">
      <div class="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 text-center sm:flex-row sm:text-left">
        <p class="text-sm text-[#756b60] dark:text-[#928982]">
          &copy; {{ currentYear }} {{ siteName }}. {{ t('home.footer.allRightsReserved') }}
        </p>
        <a
          v-if="docUrl"
          :href="docUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="text-sm text-[#756b60] transition-colors hover:text-[#201812] dark:text-[#928982] dark:hover:text-white"
        >
          {{ t('home.docs') }}
        </a>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore, useAppStore } from '@/stores'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import Icon from '@/components/icons/Icon.vue'

const { t } = useI18n()

const authStore = useAuthStore()
const appStore = useAppStore()

const siteName = computed(() => appStore.cachedPublicSettings?.site_name || appStore.siteName || 'easyAI')
const siteLogo = computed(() => appStore.cachedPublicSettings?.site_logo || appStore.siteLogo || '')
const docUrl = computed(() => appStore.cachedPublicSettings?.doc_url || appStore.docUrl || '')
const homeContent = computed(() => appStore.cachedPublicSettings?.home_content || '')

const isHomeContentUrl = computed(() => {
  const content = homeContent.value.trim()
  return content.startsWith('http://') || content.startsWith('https://')
})

const isDark = ref(document.documentElement.classList.contains('dark'))

const isAuthenticated = computed(() => authStore.isAuthenticated)
const isAdmin = computed(() => authStore.isAdmin)
const dashboardPath = computed(() => isAdmin.value ? '/admin/dashboard' : '/dashboard')
const userInitial = computed(() => {
  const user = authStore.user
  if (!user || !user.email) return ''
  return user.email.charAt(0).toUpperCase()
})

const currentYear = computed(() => new Date().getFullYear())

function toggleTheme() {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
}

function initTheme() {
  const savedTheme = localStorage.getItem('theme')
  if (
    savedTheme === 'dark' ||
    (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)
  ) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }
}

onMounted(() => {
  initTheme()
  authStore.checkAuth()

  if (!appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
})
</script>
