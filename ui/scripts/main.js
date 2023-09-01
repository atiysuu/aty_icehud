$(function () {
	let buckleSound = false;
	let framework
	let carHud = false
	let alwaysMap = false

	window.addEventListener("message", function (event) {
		let data = event.data
		if (event.data.action == "loaded") {
			if (data.speedUnit == "kmh") {$(".speed-unit").text("KMH")} else {$(".speed-unit").text("MPH")}
			data.voiceHud ? $(".voicehud").show() : $(".voicehud").hide()
			data.playerStats ? $(".stats").show() : $(".stats").hide()
			data.statusHud ? $(".status").show() : $(".status").hide()
			data.carHud ? carHud = true && $(".carhud").show() && $(".carhud").css("display", "flex") : $(".carhud").hide()
			framework = data.framework
			alwaysMap = data.alwaysMap
		}

		if (event.data.action == "VehicleInfo") {
			let speed = event.data.vehicleSpeed;
			let health = event.data.vehicleHealth;
			let rpm = event.data.rpm;
			let fuel = event.data.fuel;

			$(".speed").text(String(speed).padStart(3, "0"));
			$(".rpm-bar").css("width", rpm + "%");
			$(".fuel-bar").css("height", fuel + "%");

			if (fuel <= 40 && fuel >= 20) {
				$(".fuel").attr("src", "img/fuel40.png");
				$(".fuel-bar").css("background-color", "#FFA229");
			} else if (fuel <= 20) {
				$(".fuel").attr("src", "img/fuel20.png");
				$(".fuel-bar").css("background-color", "#FF2929");
			} else {
				$(".fuel").attr("src", "img/fuel.png");
				$(".fuel-bar").css("background-color", "#FFFFFF");
			}

			if (health <= 700 && health >= 500) {
				$(".engine").attr("src", "img/engine700.png");
				$(".engine").css("opacity", "0.8");
			} else if (health < 500) {
				$(".engine").attr("src", "img/engine500.png");
				$(".engine").css("opacity", "0.8");
			} else {
				$(".engine").attr("src", "img/engine.png");
				$(".engine").css("opacity", "0.3");
			}
		}

		if (event.data.action == "cruise") {
			event.data.status ? $(".cruise").css("opacity", "0.8") : $(".cruise").css("opacity", "0.3");
		}

		if (event.data.action == "belt") {
			let SeatBelt = event.data.status;
			
			if (SeatBelt) {
				$(".belt").css("opacity", "0.8");
				if (!buckleSound) {
					buckleSound = true;
					playBuckleSound();
				}
			} else {
				$(".belt").css("opacity", "0.3");
				if (buckleSound) {
					buckleSound = false;
					playUnbuckleSound();
				}
			}
		}

		if (event.data.action == "talkingState") {
			if (event.data.state){
				$(".voicehud").css("opacity", "1.0");
			}else{
				$(".voicehud").css("opacity", "0.3");
			}
		}

		if (event.data.action == "voiceMod") {
			if (event.data.value == 1) {
				$(".voicehud .voice .one").css("background-color", "#fff");
				$(".voicehud .voice .two").css("background", "none");
				$(".voicehud .voice .sec").css("background", "none");
			} else if (event.data.value == 2) {
				$(".voicehud .voice .one").css("background-color", "#fff");
				$(".voicehud .voice .two").css("background-color", "#fff");
				$(".voicehud .voice .sec").css("background", "none");
			} else if (event.data.value == 3) {
				$(".voicehud .voice .one").css("background-color", "#fff");
				$(".voicehud .voice .two").css("background-color", "#fff");
				$(".voicehud .voice .sec").css("background-color", "#fff");
			}
		}

		if (event.data.action == "other") {
			$(".location .location-text").text(event.data.street);

			if (event.data.inCar){
				if (carHud) {
					$(".carhud").css("display", "flex");
					$(".carhud").css("right", "35px");
				} 

				$(".map-outline").fadeIn();
				$(".stamina-wrapper").fadeOut();
				if (!alwaysMap){
					$(".status-wrapper").css("left", "15vw");
					$(".location").css({
						bottom: "19vh",
						left: "0",
					});
				}
			}else{
				$(".carhud").fadeOut();
				$(".carhud").css("right", "-335px");
				$(".rpm-bar").css("width", "0%");
				$(".map-outline").fadeOut();
				$(".stamina-wrapper").fadeIn();
				if (!alwaysMap){
					$(".status-wrapper").css("left", "0px");
					$(".location").css({
						bottom: "1vh",
						left: "50px",
					});
				}
			}
		}

		if (event.data.action == "StatsUpdate") {
			$(".stats").css("display", "flex");
			$(".id span").text(event.data.playerId);
			$(".ping span").text(event.data.playerPing + "ms");
			$(".bank span").text("$" + event.data.playerCash);
			$(".cash span").text("$" + event.data.playerBank);
		}

		if (event.data.action == "StatusUpdate") {
			let health = event.data.health;
			let armor = event.data.armor;
			let stamina = event.data.stamina;
			let oxygen = event.data.oxygen;
			let inWater = event.data.inWater;

			if (framework != "standalone"){
				let thirst = event.data.thirst
				let hunger = event.data.hunger

				$(".thirst").css(
					"background-image",
					`conic-gradient(#fff ` + thirst + `%, transparent ` + (thirst - 100) + `%, transparent)`
				);

				$(".hunger").css(
					"background-image",
					`conic-gradient(#fff ` + hunger + `%, transparent ` + (hunger - 100) + `%, transparent)`
				);
			}else{
				$(".thirst-wrapper, .hunger-wrapper").hide()
				$(".stats .bottom").hide()
			}

			$(".location .location-text").text(event.data.street);

			if (armor == 0) {
				$(".armour-wrapper").fadeOut();
			} else if (armor > 0) {
				$(".armour-wrapper").fadeIn();
			}

			if (inWater) {
				$(".oxygen-wrapper").fadeIn();
			} else{
				$(".oxygen-wrapper").fadeOut();
			}

			$(".health").css(
				"background-image",
				`conic-gradient(#fff ` + health + `%, transparent ` + (health - 100) + `%, transparent)`
			);
			$(".armour").css(
				"background-image",
				`conic-gradient(#fff ` + armor + `%, transparent ` + (armor - 100) + `%, transparent)`
			);
			$(".stamina").css(
				"background-image",
				`conic-gradient(#fff ` + stamina + `%, transparent ` + (stamina - 100) + `%, transparent)`
			);
			$(".oxygen").css(
				"background-image",
				`conic-gradient(#fff ` + oxygen + `%, transparent ` + (oxygen - 100) + `%, transparent)`
			);
		}

		if (event.data.action == "loggedIn") {
			if(event.data.status){
				$("body").fadeIn()
			}else{
				$("body").fadeOut()
			}
		}
	});
});

let buckleSound = new Audio();
buckleSound.src = "sounds/buckle.mp3";
let unbuckleSound = new Audio();
unbuckleSound.src = "sounds/unbuckle.mp3";

function playBuckleSound() {
	buckleSound.play();
}

function playUnbuckleSound() {
	unbuckleSound.play();
}
