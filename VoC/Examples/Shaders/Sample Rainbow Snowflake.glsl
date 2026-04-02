#version 420

// original https://www.shadertoy.com/view/tl3fD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Arthur Jacquin - 2021
// https://www.linkedin.com/in/arthur-jacquin-631921153/
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//Inspired by https://www.youtube.com/watch?v=il_Qg9AqQkE&t=369s

#define PI 3.14159265359

vec2 GetDirection(float angle)
{
    return vec2(sin(angle), cos(angle));
}

void main(void)
{
    vec2 st = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y; //UVs centré

    //Pour les symetries
    st *= 1.25;
    st.x = abs(st.x);

    float angle = 5.0 / 6.0 * PI;
    st.y += tan(angle) * 0.5; //Centrage en hauteur
    vec2 n = GetDirection(angle); //Direction de l'axe de symetrie
    float axeSym = dot(st - vec2(.5, 0), n); //Axe de symetrie
    st -= n * max(0., axeSym) * 2.; //On applique la symétrie

    angle = 2.0 / 3.0 * PI;
    n = GetDirection(angle); //Direction de l'axe de symetrie
    
    const int it = 4; //Nombre d'iterations
    float scale = 1.; //scale appliqué pour décompression plus tard
    
    st.x += .5; //Centrage
    for(int i = 0; i < it; i++)
    {
        scale *= 3.;
        st *= 3.;
        st.x -= 1.5;

        st.x = abs(st.x); //Symetrie en X
        st.x -= 0.5; //Aggrandissement de la ligne
        
        float axe = dot(st, n); //Axe de symetrie
        st -= n * min(0., axe) * 2.; //On applique la symétrie

    }

    //line shape 1 pixel d'épaisseur
    vec3 col = 0.5 + 0.5*cos(time - st.yyy + vec3(6,4,2));
    float d = length(st - vec2(clamp(st.x, -1., 1.), 0));
    col.rg += st / scale;
    
    glFragColor = vec4(col, 1.0);
}
