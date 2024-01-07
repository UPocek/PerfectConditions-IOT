extern crate rocket;
use chrono::{DateTime, FixedOffset};
use diesel::prelude::*;
use influxdb2::FromDataPoint;
use rocket::serde::{Deserialize, Serialize};

use crate::models::{Plant, Type};

#[derive(Serialize, Deserialize, Queryable)]
pub struct BasicTypeDTO {
    pub type_id: String,
    pub type_name: String,
}

impl BasicTypeDTO {
    fn new(type_id: String, type_name: String) -> Self {
        Self { type_id, type_name }
    }

    pub fn from_plant_type(plant_type: Type) -> Self {
        Self::new(plant_type.id, plant_type.type_name)
    }
}

#[derive(Serialize, Deserialize, Queryable)]
pub struct FullTypeDTO {
    pub id: String,
    pub type_name: String,
    pub light_intensity_need: f64,
    pub soil_moisture_need: i32,
    pub temperature_need: f64,
    pub humidity_need: f64,
    pub pressure_need: f64,
}

impl FullTypeDTO {
    fn new(
        id: String,
        type_name: String,
        light_intensity_need: f64,
        soil_moisture_need: i32,
        temperature_need: f64,
        humidity_need: f64,
        pressure_need: f64,
    ) -> Self {
        Self {
            id,
            type_name,
            light_intensity_need,
            soil_moisture_need,
            temperature_need,
            humidity_need,
            pressure_need,
        }
    }

    pub fn from_plant_type(plant_type: Type) -> Self {
        Self::new(
            plant_type.id,
            plant_type.type_name,
            plant_type.light_intensity_need,
            plant_type.soil_moisture_need,
            plant_type.temperature_need,
            plant_type.humidity_need,
            plant_type.pressure_need,
        )
    }
}

#[derive(Serialize, Deserialize)]
pub struct NewPlantDTO {
    pub plant_name: String,
    pub plant_type_id: String,
}

#[derive(Serialize, Deserialize, Queryable)]
pub struct PlantDTO {
    pub plant_id: String,
    pub plant_name: String,
    pub plant_type_id: String,
    pub plant_type_name: String,
    pub light_intensity_need: f64,
    pub soil_moisture_need: i32,
    pub temperature_need: f64,
    pub humidity_need: f64,
    pub pressure_need: f64,
}

impl PlantDTO {
    pub fn new(
        plant_id: String,
        plant_name: String,
        plant_type_id: String,
        plant_type_name: String,
        light_intensity_need: f64,
        soil_moisture_need: i32,
        temperature_need: f64,
        humidity_need: f64,
        pressure_need: f64,
    ) -> Self {
        Self {
            plant_id,
            plant_name,
            plant_type_id,
            plant_type_name,
            light_intensity_need,
            soil_moisture_need,
            temperature_need,
            humidity_need,
            pressure_need,
        }
    }

    pub fn from_plant_and_type(plant: Plant, plant_type: Type) -> Self {
        Self::new(
            plant.id,
            plant.plant_name,
            plant_type.id,
            plant_type.type_name,
            plant_type.light_intensity_need,
            plant_type.soil_moisture_need,
            plant_type.temperature_need,
            plant_type.humidity_need,
            plant_type.pressure_need,
        )
    }
}

#[derive(Serialize, Deserialize, Queryable)]
pub struct PlantResponseDTO {
    pub plant_id: String,
    pub plant_name: String,
    pub plant_type_id: String,
    pub plant_type_name: String,
    pub light_intensity_need: f64,
    pub soil_moisture_need: i32,
    pub temperature_need: f64,
    pub humidity_need: f64,
    pub pressure_need: f64,
    pub current_heat_index: f64,
    pub current_humidity: f64,
    pub current_lux: f64,
    pub current_moisture: f64,
    pub current_pressure: f64,
    pub current_temperature: f64,
}

impl PlantResponseDTO {
    pub fn new(
        plant_id: String,
        plant_name: String,
        plant_type_id: String,
        plant_type_name: String,
        light_intensity_need: f64,
        soil_moisture_need: i32,
        temperature_need: f64,
        humidity_need: f64,
        pressure_need: f64,
        current_heat_index: f64,
        current_humidity: f64,
        current_lux: f64,
        current_moisture: f64,
        current_pressure: f64,
        current_temperature: f64,
    ) -> Self {
        Self {
            plant_id,
            plant_name,
            plant_type_id,
            plant_type_name,
            light_intensity_need,
            soil_moisture_need,
            temperature_need,
            humidity_need,
            pressure_need,
            current_heat_index,
            current_humidity,
            current_lux,
            current_moisture,
            current_pressure,
            current_temperature,
        }
    }

    pub fn from_plant_and_reading(plant: PlantDTO, reading: SensorReading) -> Self {
        Self::new(
            plant.plant_id,
            plant.plant_name,
            plant.plant_type_id,
            plant.plant_type_name,
            plant.light_intensity_need,
            plant.soil_moisture_need,
            plant.temperature_need,
            plant.humidity_need,
            plant.pressure_need,
            reading.heat_index,
            reading.humidity,
            reading.lux,
            reading.moisture,
            reading.pressure,
            reading.temperature,
        )
    }

    pub fn from_plant_and_type_and_reading(
        plant: Plant,
        plant_type: Type,
        reading: SensorReading,
    ) -> Self {
        Self::new(
            plant.id,
            plant.plant_name,
            plant_type.id,
            plant_type.type_name,
            plant_type.light_intensity_need,
            plant_type.soil_moisture_need,
            plant_type.temperature_need,
            plant_type.humidity_need,
            plant_type.pressure_need,
            reading.heat_index,
            reading.humidity,
            reading.lux,
            reading.moisture,
            reading.pressure,
            reading.temperature,
        )
    }
}

#[derive(Debug, FromDataPoint, Serialize, Clone)]
pub struct SensorReading {
    heat_index: f64,
    humidity: f64,
    lux: f64,
    moisture: f64,
    pressure: f64,
    temperature: f64,
}

impl Default for SensorReading {
    fn default() -> Self {
        Self {
            heat_index: 0_f64,
            humidity: 0_f64,
            lux: 0_f64,
            moisture: 0_f64,
            pressure: 0_f64,
            temperature: 0_f64,
        }
    }
}

#[derive(Debug, FromDataPoint, Serialize, Clone)]
pub struct ReadingHistory {
    value: f64,
    time: DateTime<FixedOffset>,
}

impl Default for ReadingHistory {
    fn default() -> Self {
        Self {
            value: 0_f64,
            time: chrono::MIN_DATETIME.with_timezone(&chrono::FixedOffset::east(6 * 3600)),
        }
    }
}

#[derive(Serialize)]
pub struct GenericResponse {
    pub status: String,
    pub message: String,
}
