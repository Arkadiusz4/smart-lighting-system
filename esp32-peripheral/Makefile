IDF_PATH := /Users/amika/Documents/esp/esp-idf
PORT := /dev/cu.usbmodem1101
BAUD := 115200
TARGET := esp32c3

GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RESET := \033[0m

ESP_EXPORT := source $(IDF_PATH)/export.sh
ERASE_FLASH := idf.py -p $(PORT) erase-flash
SET_TARGET := idf.py set-target $(TARGET)
BUILD := idf.py build
FLASH := idf.py -p $(PORT) -b $(BAUD) flash monitor

# Targets
.PHONY: init build flash build-flash erase monitor all

init:
	@echo -e "$(BLUE)Initializing environment and setting target...$(RESET)"
	@$(ESP_EXPORT) && $(SET_TARGET)
	@echo -e "$(GREEN)Initialization complete. Target set to $(TARGET).$(RESET)"

flash:
	@echo -e "$(BLUE)Starting flash process...$(RESET)"
	@$(ESP_EXPORT) && $(ERASE_FLASH)
	@echo -e "$(YELLOW)Flash erased.$(RESET)"
	@echo -e "$(BLUE)Flashing firmware and starting monitor...$(RESET)"
	@$(FLASH)

erase:
	@echo -e "$(BLUE)Starting erasing process...$(RESET)"
	@$(ESP_EXPORT) && $(ERASE_FLASH)
	@echo -e "$(YELLOW)Flash erased.$(RESET)"

build:
	@echo -e "$(BLUE)Building the project...$(RESET)"
	@$(ESP_EXPORT) && $(BUILD)
	@echo -e "$(GREEN)Build complete.$(RESET)"

build-flash:
	@echo -e "$(BLUE)Building the project...$(RESET)"
	@$(ESP_EXPORT) && $(BUILD)
	@echo -e "$(GREEN)Build complete.$(RESET)"
	@echo -e "$(BLUE)Starting flash process...$(RESET)"
	@$(ERASE_FLASH)
	@echo -e "$(YELLOW)Flash erased.$(RESET)"
	@echo -e "$(BLUE)Flashing firmware and starting monitor...$(RESET)"
	@$(FLASH)

monitor:
	@echo -e "$(BLUE)Starting flash with monitor...$(RESET)"
	@$(ESP_EXPORT) && $(FLASH)

all:
	@echo -e "$(BLUE)Starting full process: Build, Erase Flash, Flash, and Monitor...$(RESET)"
	@$(ESP_EXPORT) && $(BUILD)
	@echo -e "$(GREEN)Build complete.$(RESET)"
	@$(ERASE_FLASH)
	@echo -e "$(YELLOW)Flash erased.$(RESET)"
	@echo -e "$(BLUE)Flashing firmware and starting monitor...$(RESET)"
	@$(FLASH)