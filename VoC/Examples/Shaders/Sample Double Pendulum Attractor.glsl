#version 420

// original https://www.shadertoy.com/view/MtsyWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** Double pendulum fractal shader
    Copyright (C) 2017  Alexander Kraus <nr4@z10.info>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//lengths
float L1 = 2.;
float L2 = 1.;

//masses
float M1 = 3.5;
float M2 = 0.1;

//constants
float G = 9.81;

//runge kutta params
float h = 1.e-1;
float tmax = 10.;

//math params
float PI = 3.14159;

/**eval system of differential equations
params:
tp[0]: theta1
tp[1]: theta2
tp[2]: ptheta1
tp[3]: ptheta2
*/
vec4 f(vec4 tp)
{
    float C1 = tp[2]*tp[3]*sin(tp[0]-tp[1])/(L1*L2*(M1+M2*pow(sin(tp[0]-tp[1]),2.)));
    float C2 = (L2*L2*M2*tp[2]*tp[2]+L1*L1*(M1+M2)*tp[3]*tp[3]-L1*L2*M2*tp[2]*tp[3]*cos(tp[0]-tp[1]))*sin(2.*(tp[0]-tp[1]))/(2.*L1*L1*L2*L2*pow(M1+M2*pow(sin(tp[0]-tp[1]),2.),2.));
    
    vec4 ret;
    
    ret[0] = (L2*tp[2]-L1*tp[3]*cos(tp[0]-tp[1]))/(L1*L1*L2*(M1+M2*pow(sin(tp[0]-tp[1]),2.)));
    ret[1] = (L1*(M1+M2)*tp[3]-L2*M2*tp[2]*cos(tp[0]-tp[1]))/(L1*L2*L2*M2*(M1+M2*pow(sin(tp[0]-tp[1]),2.)));
    ret[2] = -(M1+M2)*G*L1*sin(tp[0])-C1+C2;
    ret[3] = -M2*G*L2*sin(tp[1])+C1-C2;
    
    return ret;    
}

vec4 step_rk4(vec4 tp)
{
    vec4 k1 = f(tp);
    vec4 k2 = f(tp + h/2.*k1);
    vec4 k3 = f(tp + h/2.*k2);
    vec4 k4 = f(tp + h*k3);
    return tp + h/6.*(k1+2.*k2+2.*k3+k4);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    M1 = 3.+1.9*sin(time);
    M2 = 2.+1.9*cos(2.*time);
    
    L1 = 2.+0.5*sin(time);
    L2 = 1.+0.2*cos(3.*time);
    
    vec4 state = vec4(uv*2.*PI/*-vec2(PI,PI)*/, 0, 0);
    float time = 0.;
    while(time < tmax) 
    {
        state = step_rk4(state);
        time += h;
    }
    
    const int ncolors = 10;
    vec4 color_list[ncolors] = vec4[ncolors]( vec4(1.,156./255., 19./255.,1.), vec4(232./255., 98./255., 12./255., 1.), vec4(1.,53./255., 0., 1.), vec4(232./255.,16./255.,12./255.,1.), vec4(1., 10./255., 150./255., 1.), vec4(1., 235./255., 10./255., 1.), vec4(195./255.,232./255., 12./255., 1.), vec4(97./255., 1., 0., 1.), vec4(12./255., 232./255., 25./255., 1.), vec4(13./255., 1. ,117./255., 1.) );
glFragColor = vec4(0.,0.,0.,1.0);
    
    if(state[1] < PI/2.)
        glFragColor = vec4(0.,0.,0.,1.);
    else if(state[1] < PI/2.+2.*PI)
        glFragColor = color_list[0];
    else if(state[1] < PI/2.+4.*PI)
        glFragColor = color_list[1];
    else if(state[1] < PI/2.+6.*PI)
        glFragColor = color_list[2];
    else if(state[1] < PI/2.+8.*PI)
        glFragColor = color_list[3];
    else if(state[1] < PI/2.+10.*PI)
        glFragColor = color_list[4];
    else if(state[1] < PI/2.+12.*PI)
        glFragColor = color_list[5];
    else if(state[1] < PI/2.+14.*PI)
        glFragColor = color_list[6];
    else if(state[1] < PI/2.+16.*PI)
        glFragColor = color_list[7];
    else if(state[1] < PI/2.+18.*PI)
        glFragColor = color_list[8];
    else if(state[1] < PI/2.+20.*PI)
        glFragColor = color_list[9];
    else 
        glFragColor = vec4(0.,0.,1.,1.);
    
}
