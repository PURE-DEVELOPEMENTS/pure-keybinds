-- database.sql
-- Key Binding System Database Structure

CREATE TABLE IF NOT EXISTS `player_keybinds` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `key_name` VARCHAR(20) NOT NULL,
    `command` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_citizen_key` (`citizenid`, `key_name`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional: Add some example data for testing
-- INSERT INTO `player_keybinds` (`citizenid`, `key_name`, `command`) VALUES
-- ('ABC12345', 'F1', 'me waves'),
-- ('ABC12345', 'F4', 'do looks around'),
-- ('DEF67890', 'A', 'emote salute');