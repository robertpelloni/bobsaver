#version 120

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

// metaball by @h013

float metaball(vec3 p, vec4 spr){
