const warmPrimary = {
  50: '#fff4ef',
  100: '#ffe5d9',
  200: '#ffc8b3',
  300: '#f4a184',
  400: '#df8a6c',
  500: '#d9795a',
  600: '#bd5f42',
  700: '#984933',
  800: '#713526',
  900: '#4f241b',
  950: '#2d130d'
}

const warmNeutral = {
  50: '#f6f4ef',
  100: '#e8e3da',
  200: '#d2cabd',
  300: '#b7ad9f',
  400: '#92887c',
  500: '#746b60',
  600: '#585149',
  700: '#3a3833',
  800: '#23221f',
  900: '#171614',
  950: '#11100e'
}

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // 主色调 - 暖橙/珊瑚色系
        primary: warmPrimary,
        // 辅助色 - 暖棕灰
        accent: warmNeutral,
        // 深色模式背景 - 暖黑
        dark: warmNeutral,
        // 兼容旧页面里直接写的 Tailwind 默认色名，避免到处逐个改 class。
        gray: warmNeutral,
        slate: warmNeutral,
        zinc: warmNeutral,
        neutral: warmNeutral,
        blue: warmPrimary,
        sky: warmPrimary,
        cyan: warmPrimary,
        teal: warmPrimary,
        indigo: warmPrimary,
        purple: warmPrimary
      },
      fontFamily: {
        sans: [
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'PingFang SC',
          'Hiragino Sans GB',
          'Microsoft YaHei',
          'sans-serif'
        ],
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'monospace']
      },
      boxShadow: {
        glass: '0 12px 40px rgba(0, 0, 0, 0.18)',
        'glass-sm': '0 6px 18px rgba(0, 0, 0, 0.14)',
        glow: '0 0 22px rgba(223, 138, 108, 0.22)',
        'glow-lg': '0 0 44px rgba(223, 138, 108, 0.30)',
        card: '0 18px 50px rgba(0, 0, 0, 0.18), inset 0 1px 0 rgba(255, 255, 255, 0.03)',
        'card-hover': '0 22px 60px rgba(0, 0, 0, 0.24)',
        'inner-glow': 'inset 0 1px 0 rgba(255, 255, 255, 0.06)'
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-primary': 'linear-gradient(135deg, #f4a184 0%, #bd5f42 100%)',
        'gradient-dark': 'linear-gradient(135deg, #23221f 0%, #11100e 100%)',
        'gradient-glass':
          'linear-gradient(135deg, rgba(246,244,239,0.08) 0%, rgba(246,244,239,0.03) 100%)',
        'mesh-gradient':
          'radial-gradient(at 38% 0%, rgba(223, 138, 108, 0.10) 0px, transparent 45%), radial-gradient(at 82% 8%, rgba(180, 126, 74, 0.08) 0px, transparent 42%), radial-gradient(at 0% 58%, rgba(113, 53, 38, 0.12) 0px, transparent 45%)'
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        shimmer: 'shimmer 2s linear infinite',
        glow: 'glow 2s ease-in-out infinite alternate'
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        slideDown: {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(20px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' }
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' }
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' }
        },
        glow: {
          '0%': { boxShadow: '0 0 20px rgba(223, 138, 108, 0.22)' },
          '100%': { boxShadow: '0 0 30px rgba(223, 138, 108, 0.34)' }
        }
      },
      backdropBlur: {
        xs: '2px'
      },
      borderRadius: {
        '4xl': '2rem'
      }
    }
  },
  plugins: []
}
