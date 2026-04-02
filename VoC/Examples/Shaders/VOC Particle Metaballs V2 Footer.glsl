
    //--
    O.xyz = vec3( min(max(-d, 0.0), 1.0) ) * c *1.5; // *1.5 to brighten color output
    O.xyz *= 0.25 + pow(-d/60.0, 0.2)*0.75;

    glFragColor = O;
}
