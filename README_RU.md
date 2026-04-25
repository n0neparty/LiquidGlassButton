# AI Chat App - iOS 26 Liquid Glass Edition

## 🌟 Описание

Премиум iOS приложение для общения с различными AI моделями, полностью построенное на **iOS 26 Liquid Glass** дизайн-языке от Apple (WWDC25).

## ✨ Что такое Liquid Glass?

**Liquid Glass** - это динамический дизайн-язык, представленный на WWDC25 для iOS 26. Он выходит за рамки традиционного glassmorphism, добавляя:

- 🔮 **Real-time Light Bending (Lensing)** - настоящее преломление света вместо blur
- 🌊 **Fluid Morphing** - плавные трансформации между формами
- ✨ **Interactive Specular Highlights** - отклик на касания и движение устройства
- 🎨 **Adaptive Tinting** - автоматическая адаптация цвета к контенту

## 🎯 Особенности приложения

### AI Провайдеры (8 штук)
- **Grok** (Merlin, G4F) - молниеносные ответы
- **ChatGPT** (GitHub Models, Merlin) - универсальный помощник
- **Gemini** (Google, Merlin) - мультимодальный AI
- **Claude** (Merlin, G4F) - аналитический ассистент
- **Mistral** (Mistral AI) - европейский AI
- **DeepSeek** (G4F, Merlin) - глубокое мышление
- **Llama** (GitHub Models, G4F) - открытая модель
- **Qwen** (G4F) - китайский AI

### 📱 Экраны с Liquid Glass

#### 1. Главный экран (HomeView)
- **Экран загрузки** с materialization эффектом
- **Hero section** с большим заголовком
- **Action cards** (suggestion chips) с lensing
- **Input bar** с интерактивными glass кнопками
- **Model pill** с fluid morphing при смене модели

#### 2. Экран чата (ChatView)
- **Message bubbles** с glass эффектом
- Пользователь справа, AI слева
- **Interactive feedback** при касании
- **Fluid scrolling** с spring анимациями

#### 3. Настройки (SettingsView)
- **Glass cards** для провайдеров и моделей
- **Animated checkmarks** при выборе
- **Morphing transitions** между состояниями

## 🛠️ Технические требования

- **iOS 26.0+** (обязательно для Liquid Glass API)
- **Xcode 16.0+**
- **Swift 6.0**
- **SwiftUI 6.2+**

## 📦 Установка

### 1. Клонирование репозитория
```bash
git clone <repository-url>
cd ios-app-swift
```

### 2. Настройка API сервера
```bash
cd ../api
npm install
npm start
# Сервер запустится на http://localhost:4000
```

### 3. Настройка iOS приложения
1. Откройте `AIChatApp.xcodeproj` в Xcode 16+
2. Измените `API_BASE` в `Models.swift`:
```swift
let API_BASE = "http://YOUR_SERVER_IP:4000"
```
3. Выберите iOS 26.0+ Simulator или устройство
4. Нажмите ⌘R для запуска

## 🎨 Liquid Glass API - Примеры использования

### Базовое применение
```swift
import SwiftUI

struct MyView: View {
    @Namespace private var glassNamespace
    
    var body: some View {
        GlassEffectContainer {
            Button("Action") {
                // action
            }
            .glassEffect()
            .glassEffectID("myButton", in: glassNamespace)
            .interactive()
        }
    }
}
```

### Ключевые модификаторы

#### 1. GlassEffectContainer
Оборачивает группу glass элементов, позволяя им "видеть" друг друга:
```swift
GlassEffectContainer {
    // Все glass элементы здесь
}
```

#### 2. .glassEffect()
Применяет Liquid Glass материал:
```swift
.glassEffect()
```

#### 3. .glassEffectID()
Идентифицирует view для fluid morphing:
```swift
.glassEffectID("uniqueID", in: namespace)
```

#### 4. .interactive()
Добавляет интерактивные эффекты (scaling, bouncing, shimmer):
```swift
.interactive()
```

## 📂 Структура проекта

```
ios-app-swift/AIChatApp/
├── AIChatApp.swift          # Entry point
├── ContentView.swift        # Root view
├── HomeView.swift           # Главный экран с Liquid Glass
│   ├── GlassEffectContainer
│   ├── Top Bar (header buttons)
│   ├── Loading View (materialization)
│   ├── Center Title (hero section)
│   ├── Suggestion Chips (action cards)
│   └── Input Bar (interactive glass)
├── ChatView.swift           # Экран чата
│   ├── Message Bubbles (glass)
│   └── Input Bar (interactive)
├── SettingsView.swift       # Настройки
│   ├── Provider Cards (glass)
│   └── Model Cards (glass)
├── APIService.swift         # API клиент
└── Models.swift             # Модели данных
```

## 🎯 Кастомизация

### Изменить цвета провайдеров
Отредактируйте `Models.swift`:
```swift
AIProvider(
    id: "grok",
    name: "Grok",
    icon: "bolt.fill",
    colorHex: "#1D9BF0",  // Измените цвет
    models: [...]
)
```

### Добавить новые suggestion chips
Отредактируйте `HomeView.swift`:
```swift
let suggestions = [
    ("Tell me", "something fascinating"),
    ("Write", "professionally"),
    ("Plan", "a trip"),
    ("Explain", "like I'm 5"),
    ("Ваш текст", "ваш подтекст"),  // Добавьте свой
]
```

### Настроить анимации
Измените параметры spring:
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.75), value: state)
```

### Изменить радиус blur для glow
```swift
RadialGradient(...)
    .blur(radius: 90)  // Измените значение
```

## ⚠️ Best Practices

### ✅ Правильно:
```swift
// Используйте семантические цвета
.foregroundStyle(.primary)
.foregroundStyle(.secondary)

// Группируйте glass элементы
GlassEffectContainer {
    // элементы
}

// Добавляйте interactive для кнопок
.interactive()
```

### ❌ Неправильно:
```swift
// Не используйте хардкод цвета
.foregroundStyle(.white)

// Не забывайте GlassEffectContainer
Button { }.glassEffect()  // Без контейнера

// Не перегружайте glass эффектами
// Используйте только для структурных элементов
```

## ♿ Accessibility

Приложение автоматически поддерживает:
- **Reduce Transparency** - непрозрачный fallback
- **Dynamic Type** - масштабирование текста
- **VoiceOver** - озвучивание элементов
- **High Contrast** - семантические цвета

## 🐛 Troubleshooting

### Проблема: Glass эффект не работает
**Решение**: Убедитесь что используете iOS 26.0+ и SwiftUI 6.2+

### Проблема: Fluid morphing не плавный
**Решение**: Проверьте что используете `@Namespace` и `.glassEffectID()`

### Проблема: API не отвечает
**Решение**: 
1. Проверьте что API сервер запущен (`npm start`)
2. Измените `API_BASE` на правильный IP
3. Проверьте firewall настройки

## 📚 Дополнительные ресурсы

- [Apple Developer - Liquid Glass](https://developer.apple.com/documentation/swiftui/liquid-glass)
- [WWDC25 - Introducing Liquid Glass](https://developer.apple.com/videos/wwdc25/)
- [SwiftUI 6.2 Release Notes](https://developer.apple.com/documentation/swiftui/swiftui-release-notes)
- [API Documentation](../api/README.md)

## 📝 Changelog

См. [CHANGELOG.md](CHANGELOG.md) для полного списка изменений.

## 📄 Лицензия

MIT License

## 👥 Авторы

AI Chat App Team

---

**Наслаждайтесь премиум iOS 26 Liquid Glass опытом!** ✨🚀
