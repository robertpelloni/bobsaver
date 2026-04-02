#version 420

// original https://www.shadertoy.com/view/Msy3RD

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;
