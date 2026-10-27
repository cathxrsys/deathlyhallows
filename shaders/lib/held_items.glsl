// Glowing items in hands and on the ground: id from item.properties -> color and light level (0 = no glow).
// xyz = light color, w = level in blocks (like vanilla block light)
vec4 heldItemInfo(int id) {
    if (id == 20001) return vec4(1.00, 0.62, 0.30, 14.0); // torch, lantern, campfire, jack o'lantern, shroomlight
    if (id == 20002) return vec4(0.25, 0.75, 1.00, 10.0); // soul torch, lantern, campfire
    if (id == 20003) return vec4(1.00, 0.82, 0.45, 15.0); // glowstone, redstone lamp, ochre froglight
    if (id == 20004) return vec4(0.75, 0.95, 1.00, 15.0); // sea lantern, end rod, beacon, conduit
    if (id == 20005) return vec4(0.45, 1.00, 0.50, 15.0); // verdant froglight
    if (id == 20006) return vec4(1.00, 0.55, 0.85, 15.0); // pearlescent froglight
    if (id == 20007) return vec4(1.00, 0.38, 0.10, 15.0); // lava bucket
    if (id == 20008) return vec4(1.00, 0.15, 0.08, 7.0);  // redstone torch
    if (id == 20009) return vec4(0.80, 1.00, 0.40, 7.0);  // glow berries, glow lichen
    if (id == 20010) return vec4(0.55, 0.20, 1.00, 10.0); // crying obsidian
    return vec4(0.0);
}
