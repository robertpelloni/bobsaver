#version 420

// original https://www.shadertoy.com/view/NtcSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Swirly function

float height(vec2 p){
    for(int i=1; i<10; i++){
        p.x+=.3/float(i)*sin(float(i)*4.*p.y+time*1.);
        p.y+=.3/float(i)*cos(float(i)*4.*p.x+time*1.);
    }
    
    float r = cos(p.x+p.y+1.)*.5+.5;
    
    return r/5.;
}

// Get normal from height function using derivatives

vec3 normal(vec2 p) {
  // Originally inspired by IQ from the source I copied this from.
  vec2 eps = -vec2(1.0/resolution.y, 0.0);
  
  vec3 n;
  
  n.x = height(p + eps.xy) - height(p - eps.xy); //left height - right height
  n.y = height(p + eps.yx) - height(p - eps.yx); //down height - up height
  n.z = 2.0*eps.x;
  
  return normalize(n);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy/resolution.xy- vec2(0.5))*2.0;
    p.x *= resolution.x/resolution.y;
    p *= 0.3;
    
    // Get height and normal
    
    float h = height(p);
    vec3 n = normal(p);
    
    // Height augmented position
    
    vec3 ph = vec3(p.x,p.y,h);
    
    // Light position and direction from points to the light
    
    vec3 light = vec3(0.8,0.9,-0.9);
    vec3 ldir = normalize(light-ph);
    
    // Get shine based on angle of normal to light direction
    
    float shine = max(dot(ldir,n),0.);
    
    // Choose color, and create variable for the dark spots of the height function
    
    float fillDark = smoothstep(0.75,0.0,h*5.);
    vec3 chocolateColor = vec3(139.,69.,19.)/255.;
    
    // Base coloring
    
    vec3 col = chocolateColor +fillDark*vec3(2.,1.,1.);
    col *= h*5.;
    
    // Add 2 layers of exponentiated shine for highlights
    
    col += 0.5*pow(shine,8.);
    col += 0.1*pow(shine,2.);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
