#version 420

// original https://www.shadertoy.com/view/3lVcDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Clean Spiral Distance
 * 
 * Copyright (C) 2021  Alexander Kraus <nr4@z10.info>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const vec3 c = vec3(1.,0.,-1.);
const float pi = acos(-1.);

// Distance to spiral
float spiral(in vec2 x, in float k)
{
    float tau = 2.*pi;
    vec2 dpr = mod(vec2(atan(x.y,x.x),length(x)/k),tau);
    float a = abs(dpr.y-dpr.x);
    return k*min(a,tau-a);
}

float sm(in float d)
{
    return smoothstep(1.5/resolution.y, -1.5/resolution.y, d);
}

void main(void)
{
    // Ignore the drawing code, it's messy, I know :)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float d = spiral(uv, mix(.004,.1,.5+.5*sin(time)));
    d = abs(d)-.0025;
    float interval = clamp(.2 * (d-mod(d,.025))/.025, 0., 1.);
    vec3 col = mix(vec3(1.00,0.90,0.68), vec3(0.98,0.64,0.67), 2.*interval);
    if(interval > .5) col = mix(col, vec3(0.54,0.80,0.80), 2.*(interval-.5));
    col = mix(col, c.yyy, sm(d));
    col = mix(col, .4*c.xxx, sm(abs(mod(d+.0125,.025)-.0125)-.001));
    glFragColor = vec4(col,1.0);
}
