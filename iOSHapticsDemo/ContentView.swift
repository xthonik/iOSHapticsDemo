
import SwiftUI
import RiveRuntime // Убедитесь, что RiveRuntime добавлен в ваш проект
import CoreHaptics // Импорт для работы с тактильной обратной связью

// --- Обновленная структура HapticManager ---
// Управляет Core Haptics Engine и ОДИНОЧНЫМ воспроизведением локальных AHAP паттернов.
// ПРИМЕЧАНИЕ: Зацикливание было убрано из-за проблем с компилятором при доступе к членам CHHapticPatternPlayer.
@MainActor // Рекомендуется для работы с UI и Haptics
class HapticManager: ObservableObject {
    var engine: CHHapticEngine?

    // Свойства для хранения активных плееров (для возможности остановки)
    private var player1: CHHapticPatternPlayer?
    private var player2: CHHapticPatternPlayer?

    init() {
        // Проверяем поддержку и создаем движок
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("HapticManager: Haptics не поддерживаются.")
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
            print("HapticManager: Движок Haptics успешно создан и запущен.")

            // Обработчик перезапуска движка
            engine?.stoppedHandler = { [weak self] reason in
                print("HapticManager: Движок остановлен: \(reason). Сбрасываем плееры.")
                 self?.player1 = nil
                 self?.player2 = nil
            }
            engine?.resetHandler = { [weak self] in
                print("HapticManager: Движок сброшен. Попытка перезапуска...")
                do {
                    try self?.engine?.start()
                    print("HapticManager: Движок успешно перезапущен.")
                } catch {
                    print("HapticManager: Не удалось перезапустить движок: \(error)")
                    self?.engine = nil
                    self?.player1 = nil
                    self?.player2 = nil
                }
            }

        } catch {
            print("HapticManager: Не удалось создать или запустить движок Haptics: \(error)")
            self.engine = nil
        }
    }

    // Метод для ОДИНОЧНОГО воспроизведения локального паттерна heartbeat1.ahap
    func playHapticForPlay1() {
        guard let engine = engine else {
            print("HapticManager: Движок не доступен для Play 1.")
            return
        }
        stopHapticPlayer(&player2) // Останавливаем другой плеер

        // Получаем URL локального файла
        guard let url = Bundle.main.url(forResource: "heartbeat1", withExtension: "ahap") else {
            print("HapticManager: Не удалось найти файл heartbeat1.ahap в бандле.")
            return
        }

        do {
            // Останавливаем текущий плеер, если он уже существует
            stopHapticPlayer(&player1)

            print("HapticManager: Попытка одиночного воспроизведения для Play 1: \(url.lastPathComponent)")
            let pattern = try CHHapticPattern(contentsOf: url)
            let player = try engine.makePlayer(with: pattern)
            self.player1 = player // Сохраняем ссылку (для возможности остановки)

            // Убрана установка completionHandler и loopEnabled
            try player.start(atTime: CHHapticTimeImmediate)
            print("HapticManager: Запрос на одиночное воспроизведение для Play 1 отправлен.")

        } catch {
            print("HapticManager: Ошибка создания или запуска паттерна для Play 1 (\(url.lastPathComponent)): \(error)")
            self.player1 = nil // Сбрасываем плеер при ошибке
        }
    }

    // Метод для ОДИНОЧНОГО воспроизведения локального паттерна heartbeat2.ahap
    func playHapticForPlay2() {
         guard let engine = engine else {
             print("HapticManager: Движок не доступен для Play 2.")
             return
         }
         stopHapticPlayer(&player1) // Останавливаем другой плеер

         // Получаем URL локального файла
         guard let url = Bundle.main.url(forResource: "heartbeat2", withExtension: "ahap") else {
             print("HapticManager: Не удалось найти файл heartbeat2.ahap в бандле.")
             return
         }

         do {
             // Останавливаем текущий плеер, если он уже существует
             stopHapticPlayer(&player2)

             print("HapticManager: Попытка одиночного воспроизведения для Play 2: \(url.lastPathComponent)")
             let pattern = try CHHapticPattern(contentsOf: url)
             let player = try engine.makePlayer(with: pattern)
             self.player2 = player // Сохраняем ссылку (для возможности остановки)

             // Убрана установка completionHandler и loopEnabled
             try player.start(atTime: CHHapticTimeImmediate)
             print("HapticManager: Запрос на одиночное воспроизведение для Play 2 отправлен.")

         } catch {
             print("HapticManager: Ошибка создания или запуска паттерна для Play 2 (\(url.lastPathComponent)): \(error)")
             self.player2 = nil // Сбрасываем плеер при ошибке
         }
     }


    // Вспомогательный метод для остановки плеера
    private func stopHapticPlayer(_ player: inout CHHapticPatternPlayer?) {
         guard let existingPlayer = player else { return }
         player = nil // Обнуляем ссылку
         do {
             print("HapticManager: Остановка предыдущего плеера.")
             try existingPlayer.stop(atTime: CHHapticTimeImmediate)
         } catch {
             print("HapticManager: Ошибка при остановке предыдущего плеера: \(error)")
         }
     }


    // Метод для остановки ВСЕХ активных тактильных плееров
    func stopAllHaptics() {
        print("HapticManager: Остановка всех тактильных сигналов.")
        stopHapticPlayer(&player1)
        stopHapticPlayer(&player2)
    }
}
// --- Конец структуры HapticManager ---

// Структура представления SwiftUI (без изменений)
struct ContentView: View {
    // ViewModel для Rive анимации (используем "heart")
    @StateObject var riveViewModel = RiveViewModel(fileName: "heart", stateMachineName: "heart")

    // Менеджер для Core Haptics
    @StateObject private var hapticManager = HapticManager()

    // Состояние для отслеживания поддержки Haptics
    @State private var hapticsSupported: Bool = false

    var body: some View {
        VStack(spacing: 25) { // Вертикальный стек для размещения элементов
             Text("Демо Rive + Haptics")
                 .font(.title)

            // Отображение Rive View с использованием ViewModel
            riveViewModel.view()
                .frame(width: 300, height: 300) // Установка размера для Rive View
                .background(Color.gray.opacity(0.15)) // Небольшой фон для области Rive
                .cornerRadius(10)

            // Отображаем кнопки только если Haptics поддерживаются
            if hapticsSupported {
                // Горизонтальный стек для кнопок управления
                HStack(spacing: 30) {
                    // Кнопка для вызова триггера "play1" и одиночного тактильного отклика
                    Button {
                        print("Кнопка Play 1 нажата: Запуск Rive и Haptics (одиночный)")
                        riveViewModel.triggerInput("play1")
                        hapticManager.playHapticForPlay1() // Запускает Haptic 1 один раз
                    } label: {
                        Text("play1")
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // Кнопка для вызова триггера "play2" и одиночного тактильного отклика
                    Button {
                         print("Кнопка Play 2 нажата: Запуск Rive и Haptics (одиночный)")
                         riveViewModel.triggerInput("play2")
                         hapticManager.playHapticForPlay2() // Запускает Haptic 2 один раз
                    } label: {
                        Text("play2")
                             .padding(.horizontal, 15)
                             .padding(.vertical, 8)
                    }
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // --- КНОПКА STOP ---
                    Button {
                         print("Кнопка Stop нажата: Остановка Haptics и сброс Rive")
                         // 1. Останавливаем все активные тактильные сигналы
                         hapticManager.stopAllHaptics()
                         // 2. Сбрасываем Rive State Machine
                         riveViewModel.reset()
                    } label: {
                        Text("Stop") // Текст кнопки
                             .padding(.horizontal, 15)
                             .padding(.vertical, 8)
                    }
                    .background(Color.red) // Красный фон для Stop
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    // --- КОНЕЦ КНОПКИ STOP ---
                }
                .padding(.top, 10)
            } else {
                // Сообщение, если Haptics не поддерживаются
                Text("Кастомные тактильные сигналы не поддерживаются или не удалось инициализировать движок.")
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear {
            // Проверяем поддержку Haptics при появлении View
            hapticsSupported = hapticManager.engine != nil
            if !hapticsSupported {
                 print("ContentView: Haptics не поддерживаются или движок не инициализирован.")
            } else {
                 print("ContentView: Haptics поддерживаются, движок инициализирован.")
            }
        }
        // Добавляем остановку Haptics при исчезновении View
        .onDisappear {
            hapticManager.stopAllHaptics()
        }
    }
}

