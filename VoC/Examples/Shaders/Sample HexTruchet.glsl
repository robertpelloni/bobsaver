#version 420

// original https://www.shadertoy.com/view/7dtGRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIN_60 0.8660254

/////////////////////////////////////////////////////////////
// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

/////////////////////////////////////////////////////////////
vec3 blob( vec2 uv, vec2 p )
{
    //un-skew the uv to get round dots
    uv.x += uv.y * 0.5; //skew x to shift diagonal into triangles
    uv.x /= SIN_60;
    //also scale the position to get the origin to the correct place.
    p.x /= SIN_60;
        
    float d = distance( uv, p );
    
    float r = 0.123;
    float outer = smoothstep(r + 0.001, r - 0.001, d); //invert
    
    float rb = 0.066;
    float inner = smoothstep(rb - 0.001, rb + 0.001, d); 
    
    
    float glow = smoothstep(rb+0.3, rb, d);  //invert
    
    return vec3(outer,inner, glow);
}
/////////////////////////////////////////////////////////////
vec3 pulse( float falloff, vec3 rnd )
{
    //vec3 colA = vec3(0.4,0.01,0.0);
    //vec3 colB = vec3(1.0,0.7,0.0);
    
    vec3 colA = vec3(0.1,0.01,0.5);
    vec3 colB = vec3(0.4,0.45,1.0);
    
    float v = abs(sin(((time*(1.0+rnd.z))+rnd.x) * (rnd.y+0.1) * 5.0));
    vec3 col = mix( colA, colB, vec3(v*v*v));
    
    return col * pow( falloff, mix(7.0,3.0,v));
    
}
/////////////////////////////////////////////////////////////
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = gl_FragCoord.xy/resolution.y; //y-fov
    vec2 uv = gl_FragCoord.xy/resolution.x; //x-fov

     // Time varying pixel color
    vec3 col = vec3(0);
    
    //offset zoom centre
    uv -= 0.5;    
     
    //sacle (zoom)
    float tilesY = mix(10.0, 14.0, sin(time*0.1)*0.5+0.5); //zoom in and out
    uv *= tilesY;
    
    //pan the image 
    uv += vec2(0.45233 * time, sin(time*-0.1250235) * 1.41 );    
   
        
    //squares -> euqlaterial triangles
    uv.x *= SIN_60; //scale to get equalateral. mul by sin60 to get h == 1/2a (equalaterial triangle corner = 60deg)
    uv.x -= uv.y * 0.5; //skew x to shift diagonal into triangles
    
    vec2 id = floor(uv.xy);
    
    vec2 idRightB = id + vec2(1.0, 0.0);

    vec2 idBottomA = id + vec2(0.0, -1.0);   
    
    
    
    uv = fract(uv);
    
    //get diagonal of the skewed grid to get a triangular chequer pattern.
    float sn = sign( (uv.x+uv.y)-1.0f );
    
    uv = mix(uv, vec2(1)-uv, sn*0.5+0.5); //flip UV in top right triangle
        
    //convert the grid-id to a triangle-id
    
    float daigonalHashOffset = 1.7133453;
    
    vec2 idSign = id + ((-sn)*daigonalHashOffset);
    id += sn*daigonalHashOffset; //add some offset based on the chequer/sign 
    
    idRightB += (-sn)*daigonalHashOffset; //flipping the sign gets us the upper-right triangle in the un-skewed cell.
    idBottomA += (-sn)*daigonalHashOffset; 
    
    vec3 rnd = hash32(id); //get a noise per triangle
       
    
    float dots = 0.0;
    
    //Draw edges between triangles randomly
    int numEdges = 0;
    
    vec3 rndEdges = fract(rnd + (floor(time)*vec3(0.2,0.1,0.3)) ); //step-tick the random values by adding a 
    
    if(rndEdges.x < 0.5)
    {
        dots += smoothstep( 0.05, 0.04, abs(uv.x - 0.5));
        ++numEdges;
    }
  
    if(rndEdges.y < 0.5)
    {
        dots += smoothstep( 0.05, 0.04, abs(uv.y - 0.5));
        ++numEdges;
    }
    
    if( rndEdges.z < 0.5 && numEdges < 2 /*|| numEdges==0*/ )
    {
        dots += smoothstep( 0.05, 0.04, abs((uv.x+uv.y) - 0.5));
    }
    
    //Draw rings around the edge-centres between trianges, between the solid edges above
    vec3 dotA = blob(uv, vec2(0.5,0.0));
    vec3 dotB = blob(uv, vec2(0.25,0.5));
    vec3 dotC = blob(uv, vec2(0.75,0.5));
    
    float dotsMask = 1.0;
    
    dots += dotA.x;
    dotsMask *= dotA.y;
    
    dots += dotB.x;
    dotsMask *= dotB.y;
    
    dots += dotC.x;
    dotsMask *= dotC.y;
      
    //cut out the ring centres
        
     
    //draw backgound       
    //random dark gray triangle bg
    col = vec3((sin((time*rnd.z+rnd.x)*5.)+1.0)*0.05); 
    
    //draw wires
    //colour a bit like copper traces
    vec3 wiresCol = vec3( 0.8,0.6,0.4 );
    col = mix( col, wiresCol ,clamp(dots,0.0,1.0) );
    
    col *= dotsMask; //mask out holes to black again (ingore bg)
    
    //draw glow 
    
    //get the same random values from neighbouring triangles so the blobs on the edges match up
    vec3 rndA = hash32(idBottomA); 
    if(sn >= 0.0)
    {
        rndA = hash32(id);
    }
    
    vec3 rndB = hash32(id); 
    if(sn >= 0.0)
    {
        rndB = hash32(idRightB);
    }
    
    vec3 rndC = hash32(idSign);
    if(sn >= 0.0)
    {
        rndC = hash32(id);
    }

    col += pulse(dotA.z,rndA); 
    col += pulse(dotB.z,rndB); 
    col += pulse(dotC.z,rndC); 
    
        
    //visualise random triangle
    //col += rnd*0.25;
    
    //visualize uvs
    //col.rg += uv * 0.5;
    
       
    // Output to screen
    glFragColor = vec4(col,1.0);
}
