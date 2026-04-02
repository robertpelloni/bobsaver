#version 420

// original https://www.shadertoy.com/view/lt3yRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Flower Pattern
 * 
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const float pi = acos(-1.);
const vec3 c = vec3(1.,0.,-1.);

// compute distance to regular star
float dstar(vec2 x, float N, vec2 R)
{
    float d = pi/N,
        p0 = acos(x.x/length(x)),
        p = mod(p0, d),
        i = mod(round((p-p0)/d),2.);
    x = length(x)*vec2(cos(p),sin(p));
    vec2 a = mix(R,R.yx,i),
        p1 = a.x*c.xy,
        ff = a.y*vec2(cos(d),sin(d))-p1;
       ff = ff.yx*c.zx;
    return dot(x-p1,ff)/length(ff);
}

#define A resolution.y
#define S(v) smoothstep(-1.5/A,1.5/A,v)
void main(void)
{
    float N = 5., d = 2.*pi/N*sin(.1*time);
    vec2 uv = gl_FragCoord.xy/A-vec2(.5*resolution.x/A,.5), 
        k = vec2(cos(d),sin(d)),
        t = c.zx, e;
    mat2 R = mat2(k.x,k.y,-k.y,k.x);
    
    for(float i = 2.; i > .05; i = i*(.85+.1*sin(.3*time)))
    {
        uv = R*uv;
        e = vec2(dstar(uv, N, i*vec2(1.+.5*cos(3.4221*time),1.+.5*sin(2.153*time))),i);
        t = mix(t,e,step(-3./A,e.x));
    }
    e = vec2(.025-length(uv),pi); 
    
    //set random colors
    vec3 col = .5 + .5*cos(1.+uv.xyx+t.y*1.5e1+time+vec3(0.,2.,4.));
    glFragColor = vec4(col*mix(S(t.x),1.,.5)+S(-abs(t.x))+col.zxy*S(e.x)+S(-abs(e.x)),1.);
}
