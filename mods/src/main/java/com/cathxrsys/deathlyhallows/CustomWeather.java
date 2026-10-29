package com.cathxrsys.deathlyhallows;

import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.network.protocol.game.ClientboundGameEventPacket;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.GameRules;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.storage.ServerLevelData;

/**
 * Custom rain and thunder frequency.
 * <p>
 * In singleplayer the weather cycle of the integrated server is replaced, so the weather is real (mobs, crops, lightning).
 * On other servers the weather is simulated on the client: rain, thunder, sky and sounds follow the custom cycle
 * instead of the server's one.
 */
public final class CustomWeather {
    // the server timers are parked here while the cycle is ours; vanilla only counts them down by one per tick
    private static final int PARKED = 1_000_000;
    // fake levels change by this much per tick (vanilla: 0.01), a storm rolls in over ~10 s
    private static final float RAMP = 0.005f;

    private static final RandomSource RANDOM = RandomSource.create();

    // integrated server side
    private static final WeatherCycle serverCycle = new WeatherCycle();
    private static ServerLevel serverLevel;
    private static boolean serverOwned;
    private static boolean writtenRain, writtenThunder;

    // client side
    private static final WeatherCycle clientCycle = new WeatherCycle();
    private static Object clientConnection;
    private static float fakeRain, oFakeRain, fakeThunder, oFakeThunder;

    private CustomWeather() {}

    private static boolean isDefault() {
        return Config.rainFrequency == WeatherFrequency.DEFAULT && Config.thunderFrequency == WeatherFrequency.DEFAULT;
    }

    private static boolean simulatedOnClient() {
        return !isDefault() && !Minecraft.getInstance().hasSingleplayerServer();
    }

    // vanilla counts a parked timer down once per tick, or not at all while the weather cycle rule is off
    private static boolean isParked(int time) {
        return time >= PARKED - 2 && time <= PARKED;
    }

    private static boolean hasWeather(Level level) {
        return level.dimensionType().hasSkyLight() && !level.dimensionType().hasCeiling();
    }

    // ---- integrated server ----

    public static void tickServer(ServerLevel level, ServerLevelData data) {
        if (level.dimension() != Level.OVERWORLD) return;
        if (level != serverLevel) {
            serverLevel = level;
            serverOwned = false;
        }
        if (!level.getGameRules().getBoolean(GameRules.RULE_WEATHER_CYCLE)) return;

        if (isDefault()) {
            // hand the timers back to vanilla (0 makes it roll fresh ones)
            if (serverOwned || data.getRainTime() >= PARKED / 2 || data.getThunderTime() >= PARKED / 2) {
                data.setRainTime(0);
                data.setThunderTime(0);
                serverOwned = false;
            }
            return;
        }
        // /weather clear: vanilla runs the clear timer, the cycle resumes afterwards
        if (data.getClearWeatherTime() > 0) {
            serverOwned = false;
            return;
        }

        boolean mine = serverOwned
                && isParked(data.getRainTime()) && isParked(data.getThunderTime())
                && data.isRaining() == writtenRain && data.isThundering() == writtenThunder;
        if (!mine) {
            // a command, a sleep or a freshly loaded world changed the weather: continue from that state
            // (timers we parked ourselves in an earlier session mean nothing)
            boolean old = data.getRainTime() >= PARKED / 2;
            serverCycle.adopt(data.isRaining(), old ? 0 : data.getRainTime(), data.isThundering(), old ? 0 : data.getThunderTime());
        }
        serverOwned = true;

        serverCycle.tick(Config.rainFrequency, Config.thunderFrequency, level.getRandom());
        boolean thunder = serverCycle.thunder();
        boolean rain = serverCycle.rain()
                || thunder && WeatherCycle.bringsRain(WeatherCycle.effectiveThunder(Config.rainFrequency, Config.thunderFrequency));

        boolean wasRaining = data.isRaining();
        data.setClearWeatherTime(0);
        data.setRainTime(PARKED);
        data.setThunderTime(PARKED);
        data.setRaining(rain);
        data.setThundering(thunder);
        writtenRain = rain;
        writtenThunder = thunder;

        // vanilla compares isRaining() at the start of this very method, so it will not announce the change
        if (wasRaining != rain && level.getServer() != null) {
            level.getServer().getPlayerList().broadcastAll(new ClientboundGameEventPacket(
                    rain ? ClientboundGameEventPacket.START_RAINING : ClientboundGameEventPacket.STOP_RAINING, 0.0f), level.dimension());
        }
    }

    // ---- client simulation (not singleplayer) ----

    public static void tickClient(ClientLevel level) {
        if (isDefault() || Minecraft.getInstance().hasSingleplayerServer()) {
            clientConnection = null;
            fakeRain = oFakeRain = fakeThunder = oFakeThunder = 0.0f;
            return;
        }
        // the cycle belongs to the connection, so it survives dimension changes
        boolean fresh = clientConnection != Minecraft.getInstance().getConnection();
        if (fresh) clientConnection = Minecraft.getInstance().getConnection();

        clientCycle.tick(Config.rainFrequency, Config.thunderFrequency, RANDOM);
        boolean thunder = clientCycle.thunder();
        boolean rain = Config.rainFrequency != WeatherFrequency.DEFAULT && clientCycle.rain()
                || thunder && WeatherCycle.bringsRain(WeatherCycle.effectiveThunder(Config.rainFrequency, Config.thunderFrequency));

        oFakeRain = fakeRain;
        oFakeThunder = fakeThunder;
        fakeRain = fresh ? (rain ? 1.0f : 0.0f) : approach(fakeRain, rain ? 1.0f : 0.0f);
        fakeThunder = fresh ? (thunder ? 1.0f : 0.0f) : approach(fakeThunder, thunder ? 1.0f : 0.0f);
        if (fresh) {
            oFakeRain = fakeRain;
            oFakeThunder = fakeThunder;
        }
    }

    private static float approach(float value, float target) {
        return value < target ? Math.min(value + RAMP, target) : Math.max(value - RAMP, target);
    }

    /** Called from Level.getRainLevel on the client with the value the server gave. */
    public static float rainLevel(ClientLevel level, float real, float partial) {
        if (!simulatedOnClient() || !hasWeather(level)) return real;
        if (Config.rainFrequency == WeatherFrequency.NEVER) return 0.0f;
        float fake = Mth.lerp(partial, oFakeRain, fakeRain);
        // with default rain the server's own showers stay, storms only add to them
        return Config.rainFrequency == WeatherFrequency.DEFAULT ? Math.max(real, fake) : fake;
    }

    public static float thunderLevel(ClientLevel level, float real, float partial) {
        if (!simulatedOnClient() || !hasWeather(level)) return real;
        WeatherFrequency mode = WeatherCycle.effectiveThunder(Config.rainFrequency, Config.thunderFrequency);
        if (mode == WeatherFrequency.NEVER) return 0.0f;
        return mode == WeatherFrequency.DEFAULT ? real : Mth.lerp(partial, oFakeThunder, fakeThunder);
    }

    /** True when the thunderstorms are made up by this client: the server's own bolts are dropped and none exist nearby. */
    public static boolean replacesServerBolts() {
        return simulatedOnClient()
                && WeatherCycle.effectiveThunder(Config.rainFrequency, Config.thunderFrequency) != WeatherFrequency.DEFAULT;
    }
}
