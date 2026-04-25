# Изменения в дизайне - iOS 26 Liquid Glass Edition

## 🎨 Полная интеграция с iOS 26 Liquid Glass API

Приложение полностью переработано с использованием нативного **Liquid Glass** дизайн-языка от Apple (WWDC25).

## ✨ Ключевые особенности Liquid Glass

### 1. Real-time Light Bending (Lensing)
Вместо статичного blur, Liquid Glass **изгибает и концентрирует свет в реальном времени**, создавая эффект настоящей линзы.

### 2. Fluid Morphing
Элементы плавно **трансформируются** между состояниями благодаря `.glassEffectID()` и `Namespace`:
- Кнопки масштабируются и "дышат" при взаимодействии
- Карточки плавно появляются через модуляцию преломления света
- Переходы между экранами используют морфинг вместо простой анимации

### 3. Interactive Specular Highlights
Модификатор `.interactive()` добавляет:
- Отклик на касания (scaling, bouncing)
- Shimmer эффекты при взаимодействии
- Нативные тактильные ощущения

### 4. Adaptive Tinting
Материал автоматически адаптирует цвет на основе:
- Фонового контента
- Светлой/темной темы
- Окружающего освещения

## 🛠️ Технические детали реализации

### Core Modifiers (SwiftUI 6.2+)

```swift
// 1. GlassEffectContainer - обертка для группы элементов
GlassEffectContainer {
    // Все glass элементы внутри могут "видеть" друг друга
    // и морфить вместе
}

// 2. .glassEffect() - основной модификатор
Button { } label: {
    Image(systemName: "gearshape.fill")
        .frame(width: 44, height: 44)
}
.glassEffect() // Применяет Liquid Glass материал

// 3. .glassEffectID() - для fluid morphing
.glassEffectID("settings", in: glassNamespace)

// 4. .interactive() - интерактивные эффекты
.interactive() // Scaling, bouncing, shimmer при касании
```

### Структура кода

**HomeView.swift:**
- `@Namespace private var glassNamespace` - для fluid morphing
- `GlassEffectContainer` оборачивает весь контент
- Каждый интерактивный элемент имеет уникальный `.glassEffectID()`
- Все кнопки используют `.interactive()` для тактильного отклика

**ChatView.swift:**
- Пузыри сообщений с `.glassEffect()` и уникальными ID
- Input bar с интерактивными glass кнопками
- Fluid morphing при появлении новых сообщений

**SettingsView.swift:**
- Карточки провайдеров и моделей с glass эффектом
- Анимированные checkmark с `.transition(.scale.combined(with: .opacity))`
- Интерактивные элементы с `.interactive()`

## 📱 Визуальные улучшения

### Фон и освещение:
```swift
// Черная база
Color.black.ignoresSafeArea()

// Радиальный градиент с lensing (blur 90pt)
RadialGradient(
    colors: [
        selectedProvider.color.opacity(0.35),
        selectedProvider.color.opacity(0.18),
        .clear
    ],
    center: .init(x: 0.5, y: 0.2),
    startRadius: 0,
    endRadius: 420
)
.blur(radius: 90)
```

### Materialization (появление элементов):
Вместо простого изменения opacity, элементы **постепенно модулируют преломление света**:
```swift
withAnimation(.easeInOut(duration: 0.6)) { 
    isLoadingModel = false 
}
```

### Анимации:
- **Spring animations**: `.spring(response: 0.4, dampingFraction: 0.75)`
- **Fluid transitions**: `.easeInOut(duration: 0.7)` для градиентов
- **Interactive feedback**: автоматически через `.interactive()`

## ⚠️ Best Practices & Accessibility

### 1. Контраст и читаемость
✅ Используем семантические стили:
```swift
.foregroundStyle(.primary)   // Для основного текста
.foregroundStyle(.secondary) // Для вторичного текста
```

### 2. Reduce Transparency
Приложение автоматически уважает настройку **Settings > Accessibility > Reduce Transparency**:
- `.glassEffect()` предоставляет непрозрачный fallback
- Семантические цвета обеспечивают контраст

### 3. Избегаем перегрузки
✅ Glass используется для **структурных элементов**:
- Toolbars и navigation
- Action cards
- Input bars
- Message bubbles

❌ НЕ используется для чистой декорации

## 🎯 Системная интеграция

### Автоматические улучшения:
- **Tab Bars & Toolbars**: Floating glass look по умолчанию
- **Context Menus**: Liquid effect автоматически
- **Navigation**: Плавные морфинг-переходы

### Компоненты с Liquid Glass:
1. **Header buttons** - Settings, History, New Chat
2. **Model pill** - Центральная кнопка выбора модели
3. **Action cards** - Suggestion chips
4. **Input bar** - Текстовое поле и кнопки
5. **Message bubbles** - Пузыри сообщений в чате
6. **Settings cards** - Карточки провайдеров и моделей

## 📊 Производительность

### Оптимизации:
- `LazyVStack` для сообщений в чате
- Условный рендеринг (loading view vs main content)
- Эффективные анимации через `.spring()`
- Namespace для fluid morphing без пересоздания view

## 🚀 Требования

- **iOS 26.0+** (для Liquid Glass API)
- **SwiftUI 6.2+** (для `.glassEffect()`, `GlassEffectContainer`)
- **Xcode 16.0+**
- **Swift 6.0**

## 📝 Миграция с предыдущей версии

### Удалено:
- ❌ Кастомный `GlassmorphicCard` modifier
- ❌ Ручные `.background()` с `.ultraThinMaterial`
- ❌ Статичные обводки

### Добавлено:
- ✅ Нативный `.glassEffect()`
- ✅ `GlassEffectContainer` для группировки
- ✅ `.glassEffectID()` для fluid morphing
- ✅ `.interactive()` для тактильного отклика
- ✅ Семантические цвета (`.primary`, `.secondary`)

## 🎓 Дополнительные ресурсы

- [Apple Developer - Liquid Glass](https://developer.apple.com/documentation/swiftui/liquid-glass)
- [WWDC25 - Introducing Liquid Glass](https://developer.apple.com/videos/wwdc25/)
- [SwiftUI 6.2 Release Notes](https://developer.apple.com/documentation/swiftui/swiftui-release-notes)

## 💡 Примеры использования

### Простая кнопка с glass:
```swift
Button("Action") { }
    .glassEffect()
    .interactive()
```

### Карточка с morphing:
```swift
VStack {
    Text("Content")
}
.padding()
.glassEffect()
.glassEffectID("card", in: namespace)
.interactive()
```

### Input field:
```swift
TextField("Placeholder", text: $text)
    .padding()
    .glassEffect()
    .glassEffectID("input", in: namespace)
```

---

**Результат**: Премиум iOS 26 приложение с настоящим Liquid Glass эффектом, который "живет" и реагирует на взаимодействия пользователя! 🎉
