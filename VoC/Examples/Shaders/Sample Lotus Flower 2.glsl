#version 420

// original https://www.shadertoy.com/view/mldyzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Written by Aleksandr Pogosov,
// 2023 All rights reserved
// aleksandr7937937@gmail.com
// Originally written by me on Android (GLES) via Shader Editor application

vec3 waveCol (vec3 point, float edge_inner, float edge_outer, float time)
{
    float pLength = length(point);
    float outerRing = smoothstep(pLength + edge_outer, pLength + edge_inner,
    time);
    float innerRing = 1.0 - outerRing;
    float finalRing = innerRing * outerRing;
    vec3 vecReturn = point* vec3( finalRing);
    return vecReturn;
}

float sd_circle(vec3 point,float radius)
{
    return length(point.xy)- radius;
}

float sd_square(vec3 point,float size)
{
    return max(abs(point.x), abs(point.y))- size;
}

//PS, initially this shader was written in 3D 
//but I changed it later to 2D. 
//So most of the functions work with vec3.
//I might fix it to vec2 later but for now I `ll leave it as it is.

mat3 rotate_z(float angle)
{
return mat3(
    cos(angle), -sin(angle),0.0,
    sin(angle),cos(angle),0.0,
    0.0,0.0,1.0);
}

float sd_leaf(vec3 point)
{
    float square_1 = sd_square(point+vec3(0.5,0.5,0.0),0.5);
    float square_2 = sd_square(point-vec3(0.5,0.5,0.0),0.5);
    float squares= min(square_1, square_2);
    squares = step(0.0,squares);

    float circle = sd_circle(point, 1.);
    circle = step(0.0,circle);
    return min(circle,squares);
}

vec3 leafPosCal(vec3 vec, float rotationAngle, float distFromCenter)
{
    return vec * rotate_z(rotationAngle)+ vec3(distFromCenter,distFromCenter,0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float posCos= (cos(time)+1.)/2.;
    vec3 col = vec3(uv, .75);

    uv= uv * 2.-1.;
    uv.y*= resolution.y/resolution.x;
    uv *= 2.0;
    col += waveCol(vec3(uv,1.),0.0,1.0,
    posCos);

    vec3 uv_leaf = vec3(uv,1.);
    uv_leaf*=5.;

    // Circle at the center of the flower

    vec3 extraBackCol = vec3(0.0,0.5,1.0);
    col= mix(extraBackCol,col, sd_circle(vec3(uv,1.0),posCos));

    vec3 centerCircleCol = vec3(.7,0.0,.5);
    col= mix(centerCircleCol,col, step(0.0,sd_circle(vec3(uv,0.0),0.03)));

    // Third leaf row
    vec3 uv_leaf_3 = vec3(uv,1.);
    uv_leaf_3*=8.;

    vec3 leaf_col_3 = col/2.-vec3(
    sd_circle(vec3(uv,1.), posCos),
    0.0,
    sd_circle(vec3(uv,1.), 1.0-posCos));

    float dis_3 = 4.5;
    float timeSp_3 = 3.;

    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3, dis_3)));
    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57, -dis_3)));
    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3, -dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57,dis_3)));

    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+0.8,-dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57+0.8,dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+0.8,dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+ 1.57+0.8,-dis_3)));

    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3 + 0.392, dis_3)));
    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57 + 0.392, -dis_3)));
    col = mix(leaf_col_3,col, sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3 + 0.392, -dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57 +0.392,dis_3)));

    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.18,-dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.57+1.18,dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+1.18,dis_3)));
    col = mix(leaf_col_3,col,sd_leaf(leafPosCal(uv_leaf_3,time/timeSp_3+ 1.57+1.18,-dis_3)));

    //Second leaf row
    vec3 uv_leaf_2 = vec3(uv,1.);
    uv_leaf_2*=6.;
    vec3 leaf_col_2 = col/2.+vec3(
    sd_circle(vec3(uv,1.), posCos),
    0.0,
    sd_circle(vec3(uv,1.), 1.0-posCos));

    float dis_2 = 2.5;
    float timeSp_2 = 4.;

    col = mix(leaf_col_2,col, sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2, dis_2)));
    col = mix(leaf_col_2,col, sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+1.5, -dis_2)));
    col = mix(leaf_col_2,col, sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2, -dis_2)));
    col = mix(leaf_col_2,col,sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+1.57,dis_2)));

    col = mix(leaf_col_2,col,sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+0.8,-dis_2)));
    col = mix(leaf_col_2,col,sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+1.57+0.8,dis_2)));
    col = mix(leaf_col_2,col,sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+0.8,dis_2)));
    col = mix(leaf_col_2,col,sd_leaf(leafPosCal(uv_leaf_2,-time/timeSp_2+ 1.57+0.8,-dis_2)));

    //First leaf row
    vec3 leaf_col_1 =  col/3.- vec3(
    sd_circle(vec3(uv,1.), posCos),
    sd_circle(vec3(uv,1.),1.- posCos),
    1.0); 

    float dis_1 = 1.3;
    float timeSp_1 = 5.;
    col = mix(leaf_col_1,col, sd_leaf(leafPosCal(uv_leaf,time/timeSp_1,dis_1)));
    col = mix(leaf_col_1,col, sd_leaf(leafPosCal(uv_leaf,time/timeSp_1+1.57,-dis_1)));
    col = mix(leaf_col_1,col, sd_leaf(leafPosCal(uv_leaf,time/timeSp_1,-dis_1)));
    col = mix(leaf_col_1,col,sd_leaf(leafPosCal(uv_leaf,time/timeSp_1 + 1.57,dis_1)));

    glFragColor = vec4(col, 1.0);
}
