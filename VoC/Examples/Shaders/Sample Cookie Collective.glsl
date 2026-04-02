#version 420

// original https://www.shadertoy.com/view/wllGDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Les formes - https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec3 rotatingColor (float time) {
    float pi = 3.141592;
    float demiPi = pi / 2.0;
    
    vec3 color = vec3(0.0);
    vec3 index = vec3(mod(time, pi + demiPi) - demiPi,
                      mod(time + demiPi, pi + demiPi) - demiPi,
                      mod(time + pi, pi + demiPi) - demiPi);//Goes from -1 to 2
    
    if (index.x < demiPi)
    color.y = abs(cos(index.x));
   
    if (index.y < demiPi)
    color.z = abs(cos(index.y));
    
    if (index.z < demiPi)
    color.x = abs(cos(index.z));

    return color;
}

mat2 rotation(float a){
     float c = cos(a);
    float s = sin (a);
    
    return mat2(c,s,-s,c);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float map (vec3 pos)
{
    pos.xy *= rotation(pos.z * .3); //Faire une rotation
     pos.z -= time * .5; //Fait avancer en profondeur
    
    float size = 2.;
    pos = mod(pos, size)-size/2.; //position de la "boite" Modulo
    
    float distanceToGeometry = sdBox(pos, vec3(.45)); //Taille de la sphère
    return distanceToGeometry;
}
    
void main(void)
{
    vec2 position = gl_FragCoord.xy/resolution.xy;
    position = position *2. -1.; //Remet la position au centre 
    
    position.x *= resolution.x / resolution.y;
    
    //float circle = length(position)-0.5;
    //circle = step(abs(sin(time))/2., circle);
    //circle = step(1., circle);
    
    
    
    vec3 eye = vec3(0,0,-2);
    vec3 ray = normalize(vec3(position, 1.));
    vec3 currPos = eye;
    float shade = 0.0;
    for (int index = 0; index < 75; ++index)
    {
        float dist = map(currPos);
        if (dist < 0.0001) {
            shade = 1.0-float(index)/75.;
            break;
        }
        currPos += ray * dist *.5;
    }
    
    
    
    
    
    
    //glFragColor = vec4(pow(1.-length(pos - eye) /3., 2.));
    //glFragColor= vec4(pow(shade, 2.));
    glFragColor = vec4(shade); //shade,pow(shade/2., .7),0.,0.);
    
    float invertedShade = abs(shade - 1.0);
    glFragColor = vec4(glFragColor.xyz * rotatingColor(time - (currPos.z / 10.)),  0.0);
    glFragColor += vec4(vec3 (invertedShade),  0.0);
    
    
    //glFragColor *= (currPos.z) * (abs(sin(time) / 2.) + 0.5);
    
    //glFragColor.r = glFragColor.r * (currPos.z) * (abs(sin(time) / 2.) + 0.5);
    //glFragColor.g *= (abs(sin(time)) /3. + 0.6);
    //glFragColor.g = sin(currPos.y);
    
    
    //glFragColor = vec4(abs(position),10.*fract(time/5.)/5.,10.);
}

    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    //glFragColor = vec4(col,1.);
