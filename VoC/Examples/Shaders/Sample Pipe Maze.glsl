#version 420

// original https://www.shadertoy.com/view/4lGyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Pipe Maze
 * Copyright (C) 2018  Alexander Kraus <nr4@z10.info>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// Update 1: Simplified line(.) by using dot product with normalized orthogonal projection

const vec3 c = vec3(1.,0.,-1.);
const float pi = acos(-1.);

// Hash function
float rand(vec2 a0)
{
    return fract(sin(dot(a0.xy, vec2(12.9898,78.233)))*43758.5453);
}

// Distance to line segment
float line(vec2 x, vec2 p1, vec2 p2, float w)
{
    vec2 d = normalize(p2-p1);
    return abs(dot(x-p1, d.yx*c.zx))-w;
}

// Distance to circle
float circle(vec2 x, float r)
{
    return length(x)-r;
}

// Distance to stroke for any object
float stroke(float d, float w)
{
    return abs(d)-w;
}

// Add objects to scene with proper antialiasing
vec4 add(vec4 sdf, vec4 sda)
{
    return vec4(
        min(sdf.x, sda.x), 
        mix(sda.gba, sdf.gba, smoothstep(-1.5/resolution.y, 1.5/resolution.y, sda.x))
    );
}

// Check if specific connector near y is connected
vec2 connected(vec2 y, vec2 i)
{
    float d1 = .25*pi, d2 = .5*pi,
        p0 = atan(y.y,y.x),
        phi = mod(p0+d1, d2)-d1, 
        j = mod(round((p0-phi)/d2), 4.),
        edge = rand(mod(i,100.)+.5*j);
    return vec2(j, edge);
}

// Distance to tiled pipes
vec4 pipes(vec2 x, float d)
{
    x += .25*time*c.yx;
    float cp = .5, co = 0.;
    
    // Determine cell coordinates and cell index
    vec2 y = mod(x, d)-.5*d,
        i = round((x-y)/d + .5),
        k = connected(y,i);
    vec4 sdf = c.xyyy;
    
    // Compute pipes
    if(round(mod(i.x+i.y,2.)) == 0.)
    {
        // Half of them can be random!
        if(k.y >= cp) co = 1.;
    }
    else
    {
        // Choose orientation and number of connectors matching to neighbours
        vec2 top = connected(c.yz, i+c.yx),
            right = connected(c.zy, i+c.xy),
            bottom = connected(c.yx, i+c.yz),
            left = connected(c.xy, i+c.zy);
        if(
            ((bottom.y >= cp) && (k.x == 3.)) ||
            ((left.y >= cp) && (k.x == 2.)) ||
            ((top.y >= cp) && (k.x == 1.)) ||
            ((right.y >= cp) && (k.x == 0.))
        )
            co = 1.;
    }

    // Draw
    if(co == 1.)
        sdf = add(sdf, vec4(line(y, c.yy, .5*d*vec2(cos(.5*k.x*pi), sin(.5*k.x*pi)), .175*d), .2*c.xxx));
    sdf = add(sdf, vec4(circle(y, .25*d), .2*c.xxx));
    
    return add(sdf, vec4(stroke(sdf.x, .05*d), c.xxx));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.yy-.5;
    vec4 s = pipes(uv, .025);
    vec3 col = s.gba*smoothstep(1.5/resolution.y, -1.5/resolution.y, s.x);
    glFragColor = vec4(col,1.0);
}
