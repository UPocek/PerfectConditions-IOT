extern crate diesel;
extern crate rocket;
use crate::dtos;
use crate::models;
use crate::schema;
use crate::schema::plants;
use crate::schema::types;
use diesel::dsl::exists;
use diesel::pg::PgConnection;
use diesel::prelude::*;
use dotenvy::dotenv;
use influxdb2::models::Query;
use influxdb2::Client;
use rocket::serde::json::Json;
use rocket::tokio;
use rocket::tokio::time::{interval, Duration};
use rocket::{delete, get, http::Status, patch, post, response::status::Custom};
use rocket_contrib::json;
use std::env;
use uuid::Uuid;

// type Result<T, E = Debug<diesel::result::Error>> = std::result::Result<T, E>;

fn establish_connection_pg() -> PgConnection {
    dotenv().ok();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url))
}

fn get_influxdb_client() -> Client {
    dotenv().ok();
    let host = env::var("INFLUXDB_HOST").expect("INFLUXDB_HOST must be set");
    let org = env::var("INFLUXDB_ORG").expect("INFLUXDB_ORG must be set");
    let token = env::var("INFLUXDB_TOKEN").expect("INFLUXDB_TOKEN must be set");
    Client::new(host, org, token)
}

#[get("/all_types_basic")]
pub async fn get_types_basic() -> Result<Json<Vec<dtos::BasicTypeDTO>>, Status> {
    let connection = &mut establish_connection_pg();

    let results = types::table
        .select((types::id, types::type_name))
        .load(connection)
        .expect("Error loading types");

    Ok(Json(results))
}

#[get("/all_types_full")]
pub async fn get_types_full() -> Result<Json<Vec<dtos::FullTypeDTO>>, Status> {
    let connection = &mut establish_connection_pg();

    let results = types::table
        .select(types::all_columns)
        .load(connection)
        .expect("Error loading types");

    Ok(Json(results))
}

#[get("/all_plants?<page>&<limit>")]
pub async fn get_all(
    page: Option<usize>,
    limit: Option<usize>,
) -> Result<Json<Vec<dtos::PlantResponseDTO>>, Status> {
    let limit = limit.unwrap_or(10);
    let offset = (page.unwrap_or(1) - 1) * limit;

    let connection = &mut establish_connection_pg();

    let query = plants::table.inner_join(types::table.on(plants::type_id.eq(types::id)));

    let results = query
        .select((
            plants::id,
            plants::plant_name,
            types::id,
            types::type_name,
            types::light_intensity_need,
            types::soil_moisture_need,
            types::temperature_need,
            types::humidity_need,
            types::pressure_need,
        ))
        .limit(limit as i64)
        .offset(offset as i64)
        .load(connection)
        .expect("Error loading posts");

    let reading = get_latest_readings().await.unwrap();

    let results = results
        .into_iter()
        .map(|p| dtos::PlantResponseDTO::from_plant_and_reading(p, reading.clone()))
        .collect();

    Ok(Json(results))
}

#[post("/new_plant", data = "<body>")]
pub async fn insert(
    body: Json<dtos::NewPlantDTO>,
) -> Result<Json<dtos::PlantDTO>, Custom<Json<dtos::GenericResponse>>> {
    let uuid_id = Uuid::new_v4();
    //let datetime = Utc::now();

    let plant_to_insert = models::Plant {
        id: uuid_id.to_string(),
        plant_name: body.plant_name.to_string(),
        type_id: body.plant_type_id.to_string(),
    };

    let connection = &mut establish_connection_pg();

    let plant_exists: bool = diesel::select(exists(
        plants::table.filter(plants::plant_name.eq(&body.plant_name)),
    ))
    .get_result(connection)
    .expect("Error");

    if plant_exists {
        let error_response = dtos::GenericResponse {
            status: "fail".to_string(),
            message: format!("Plant with that name already exists"),
        };
        return Err(Custom(Status::BadRequest, Json(error_response)));
    }

    let _ = diesel::insert_into(self::schema::plants::dsl::plants)
        .values(&plant_to_insert)
        .execute(connection)
        .or_else(|_| {
            let error_response = dtos::GenericResponse {
                status: "fail".to_string(),
                message: format!("Bad Requst"),
            };
            return Err(Custom(Status::BadRequest, Json(error_response)));
        });

    let plant_type = types::table
        .find(body.plant_type_id.to_string())
        .first(connection)
        .unwrap();

    Ok(Json(dtos::PlantDTO::from_plant_and_type(
        plant_to_insert,
        plant_type,
    )))
}

#[get("/plant/<plant_id>")]
pub async fn get_by_id(
    plant_id: &str,
) -> Result<Json<dtos::PlantResponseDTO>, Custom<Json<dtos::GenericResponse>>> {
    let connection = &mut establish_connection_pg();

    let result = plants::table
        .inner_join(types::table.on(plants::type_id.eq(types::id)))
        .filter(plants::id.eq(plant_id))
        .select((
            plants::id,
            plants::plant_name,
            types::id,
            types::type_name,
            types::light_intensity_need,
            types::soil_moisture_need,
            types::temperature_need,
            types::humidity_need,
            types::pressure_need,
        ))
        .first(connection)
        .or_else(|_| {
            let error_response = dtos::GenericResponse {
                status: "fail".to_string(),
                message: format!("Plant with that id does not exists"),
            };
            return Err(Custom(Status::NotFound, Json(error_response)));
        });

    let reading = get_latest_readings().await.unwrap();

    let result = dtos::PlantResponseDTO::from_plant_and_reading(result?, reading);

    Ok(Json(result))
}

#[patch("/plant/<id>", data = "<body>")]
pub async fn update(
    id: &str,
    body: Json<dtos::NewPlantDTO>,
) -> Result<Json<dtos::PlantDTO>, Custom<Json<dtos::GenericResponse>>> {
    let connection = &mut establish_connection_pg();

    let result = diesel::update(plants::table.find(id))
        .set((
            plants::plant_name.eq(body.plant_name.to_string()),
            plants::type_id.eq(body.plant_type_id.to_string()),
        ))
        .returning(models::Plant::as_returning())
        .get_result(connection)
        .or_else(|_| {
            let error_response = dtos::GenericResponse {
                status: "fail".to_string(),
                message: format!("Plant with that id does not exists"),
            };
            return Err(Custom(Status::NotFound, Json(error_response)));
        });

    let plant_type = types::table
        .find(body.plant_type_id.to_string())
        .first(connection)
        .unwrap();

    Ok(Json(dtos::PlantDTO::from_plant_and_type(
        result?, plant_type,
    )))
}

#[delete("/plant/<id>")]
pub async fn delete(id: &str) -> Result<Status, Custom<Json<dtos::GenericResponse>>> {
    let connection = &mut establish_connection_pg();
    let _ = diesel::delete(plants::table.find(id))
        .execute(connection)
        .or_else(|_| {
            let error_response = dtos::GenericResponse {
                status: "fail".to_string(),
                message: format!("Plant with that id does not exists"),
            };
            return Err(Custom(Status::NotFound, Json(error_response)));
        });

    Ok(Status::NoContent)
}

#[get("/ws")]
pub fn echo_channel(ws: ws::WebSocket) -> ws::Channel<'static> {
    use rocket::futures::{SinkExt, StreamExt};

    ws.channel(move |mut stream: ws::stream::DuplexStream| {
        Box::pin(async move {
            let mut interval = interval(Duration::from_secs(10));

            tokio::spawn(async move {
                loop {
                    tokio::select! {
                        _ = interval.tick() => {
                            // Send message every 10 seconds
                            let reading = get_latest_readings().await.unwrap();
                            let _ = stream.send(ws::Message::Text(json!(reading).to_string())).await;
                            // println!("Sent message");
                        }
                        Some(Ok(message)) = stream.next() => {
                            match message {
                                ws::Message::Text(text) => {
                                    // Handle Text message
                                    println!("Received Text message: {}", text);
                                }
                                ws::Message::Binary(data) => {
                                    // Handle Binary message
                                    println!("Received Binary message: {:?}", data);
                                }
                                ws::Message::Close(close_frame) => {
                                    // Handle Close message
                                    println!("Received Close message: {:?}", close_frame);
                                    let close_frame = ws::frame::CloseFrame {
                                        code: ws::frame::CloseCode::Normal,
                                        reason: "Client disconected".to_string().into(),
                                    };
                                    let _ = stream.close(Some(close_frame)).await;
                                    break;
                                }
                                ws::Message::Ping(ping_data) => {
                                    // Handle Ping message
                                    println!("Received Ping message: {:?}", ping_data);
                                }
                                ws::Message::Pong(pong_data) => {
                                    // Handle Pong message
                                    println!("Received Pong message: {:?}", pong_data);
                                }
                                _ => {
                                    println!("Received other message: {:?}", message);
                                }
                            }
                        }
                        else => {
                            println!("Connection closed");
                            let close_frame = ws::frame::CloseFrame {
                                code: ws::frame::CloseCode::Normal,
                                reason: "Client disconected".to_string().into(),
                            };
                            let _ = stream.close(Some(close_frame)).await;
                            // The connection is closed by the client
                            break;
                        }
                    }
                }
            });

            tokio::signal::ctrl_c().await.unwrap();
            Ok(())
        })
    })
}

async fn get_latest_readings() -> Result<dtos::SensorReading, Box<dyn std::error::Error>> {
    let client = get_influxdb_client();
    dotenv().ok();
    let bucket = env::var("BUCKET_LATEST").expect("BUCKET_LATEST must be set");

    let qs = format!(
        "from(bucket: \"{}\")
        |> range(start: -30d)
        |> filter(fn: (r) => r._measurement == \"readings\")
        |> last()
    ",
        bucket
    );
    let query = Query::new(qs.to_string());
    let mut res: Vec<dtos::SensorReading> =
        client.query::<dtos::SensorReading>(Some(query)).await?;

    Ok(res.remove(0))
}

#[get("/history/<reading_name>/<period>/<precision_in_minutes>")]
pub async fn get_reading_history(
    reading_name: &str,
    period: &str,
    precision_in_minutes: i32,
) -> Result<Json<Vec<dtos::ReadingHistory>>, Custom<Json<dtos::GenericResponse>>> {
    let client = get_influxdb_client();
    dotenv().ok();
    let bucket = env::var("BUCKET_LATEST").expect("BUCKET_HISTORY must be set");

    let qs = format!(
        "from(bucket: \"{}\")
        |> range(start: -{})
        |> filter(fn: (r) => r._measurement == \"readings\" and r._field == \"{}\")
        |> aggregateWindow(every: {}m, fn: mean)
        |> fill(column: \"_value\", value: 0.0)
    ",
        bucket, period, reading_name, precision_in_minutes
    );
    let query = Query::new(qs.to_string());
    let res = client.query::<dtos::ReadingHistory>(Some(query)).await;
    if let Ok(result) = res {
        return Ok(Json(result));
    }

    let error_response = dtos::GenericResponse {
        status: "fail".to_string(),
        message: format!("History unavaliable"),
    };

    return Err(Custom(Status::UnprocessableEntity, Json(error_response)));
}
