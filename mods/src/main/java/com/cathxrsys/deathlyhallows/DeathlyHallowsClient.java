package com.cathxrsys.deathlyhallows;

import net.fabricmc.api.ClientModInitializer;

public class DeathlyHallowsClient implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
        Config.load();
    }
}
