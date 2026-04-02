#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NlXGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pixSize = 50.0;
const float lineWidth = 0.8;

const vec3 col1 = vec3(.1,.4, 1.);
const vec3 col2 = vec3(.1,.1,.4 );

//Dave_Hoskins's hash function
//https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main(void) {
    
    vec2 fc = gl_FragCoord.xy+time*20.;
    
    //coordinates of the cell
    vec2 uv = floor(fc / pixSize);
    
    //position inside the cell (0 to pixSize)
    vec2 diff = mod(fc,pixSize);
    
    //direction of the 2 closest cell boundaries
    vec2 clo = sign(diff-pixSize*0.5);
    
    //////
    
    // each cell is assigned a random direction (0 to 3)
    int r = int(hash12(uv)*4.);
    // w1 and w2 are integers that corresponds to the direction of closest walls
    int w1 = int(clo.x + 1.);
    int w2 = int(max(clo.y*2.0,0.0) + 1.);
    
    //
    
    //we also check 2 neighbour cells
    int rX = int( hash12(uv + vec2(clo.x,0.0))*4.0 );
    int rY = int( hash12(uv + vec2(0.0,clo.y))*4.0 );
    //oposite directions
    int wX = (w1+2)%4;
    int wY = (w2+2)%4;
    
    
    ////
        
    vec3 pix = vec3(0.0); 
    
    vec2 truc = abs(diff-pixSize*0.5) - (1.-lineWidth)*0.5*pixSize;
    
    // if our point is close to the boundary indicated by r, we draw something
    if (((r==w1)&&(truc.x>0.0))||((r==w2)&&(truc.y>0.0))) {
        pix = col1;
    }
    
    // same thing for the neigbours
    if ( (wX==rX) && (truc.x>0.0) ) {
        pix += col1;
    }

    if ( (wY==rY)  && (truc.y>0.0) ) {
        pix += col1;
    }
    
    //round ends
    if ( (dot(pix,vec3(1.)) == 0.0) && ( length(abs(diff-pixSize*0.5)-pixSize*0.5) < pixSize*lineWidth*0.5 ) ) {
        pix += col1;
    }

    //if ( (dot(pix,vec3(1.)) == 0.0) && (length(diff-pixSize*0.5) < pixSize*0.3)) {
    //    pix = vec3(.1,.1,.7);
    //}
    
    //background
    if (dot(pix,vec3(1.)) == 0.0) {
        pix = col2;
    }
    
    glFragColor = vec4(pix,1.);
    
}
