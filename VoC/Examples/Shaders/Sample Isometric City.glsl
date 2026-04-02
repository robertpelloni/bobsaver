#version 420

// original https://www.shadertoy.com/view/WsBXWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }
float sdRhombus( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p);

    float h = clamp( (-2.0*ndot(q,b) + ndot(b,b) )/dot(b,b), -1.0, 1.0 );
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    return d * sign( q.x*b.y + q.y*b.x - b.x*b.y );

}

// modefied version of the sdTriangle
float sdQuads( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p3 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p3-p2, e3 = p0-p3;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2, v3 = p -p3;

    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    vec2 pq3 = v3 - e3*clamp( dot(v3,e3)/dot(e3,e3), 0.0, 1.0 );
    
    float s = sign( e0.x*e3.y - e0.y*e3.x );
    vec2 d = min( min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                       vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                        vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) )),
                       vec2( dot( pq3, pq3 ), s*(v3.x*e3.y-v3.y*e3.x) ));

    return -sqrt(d.x)*sign(d.y);
}

vec3 isometricCube(vec2 p, vec2 pos, vec2 size, float h, vec3 col, vec3 topCol, vec3 lWallCol, vec3 rWallCol){
    float d = sdRhombus(p+pos-vec2(0.0,h),size);
    col = mix( col, topCol, smoothstep(0.01,0.0,d));
    d = sdQuads(p+pos,vec2(-size.x,0.0),vec2(-size.x,h),vec2(0.0,h-size.y),vec2(0.0,-size.y));
    col = mix( col, lWallCol, smoothstep(0.01,0.0,d));
    d = sdQuads(p+pos,vec2(0.0,-size.y),vec2(0.0,h-size.y),vec2(size.x,h),vec2(size.x,0.0));
    col = mix( col, rWallCol, smoothstep(0.01,0.0,d));
    return col;
}

vec3 isometricCar(vec2 p, vec3 col) {
    vec2 size = vec2(0.2,0.1);
    float t = time*2.0;
    vec2 pos = (vec2(-0.2,0.1)*mod(t,21.0))-vec2(-2.2,1.1);
    float h = 0.1;
    
    col = isometricCube(p+pos,vec2(-0.1,-0.0),size, h, col, vec3(0.2), vec3(0.7), vec3(0.7));    
    col = isometricCube(p+pos,vec2(-0.3,0.1),size, h, col, vec3(0.2), vec3(0.7), vec3(0.5));
    col = isometricCube(p+pos,vec2(-0.17,-0.07),size, h, col, vec3(0.2), vec3(0.7), vec3(0.5));
    return col;
}

float animateVal(float val) {
    return sin(time*2.0+val*3.0)*0.03;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.9);
    vec2 size = vec2(0.3,0.15);
    vec2 offsetPos = vec2(-0.1,0.0);
    
    // buildings
    col = isometricCube(p+vec2(1.1,-0.9),offsetPos,size, 0.1, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.3,-0.9),offsetPos,size, 0.1, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.7,-0.7),offsetPos,size, 0.5, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.9,-0.7),offsetPos,size, 0.3, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.5,-0.5),offsetPos,size, 0.2, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.1,-0.3),offsetPos,size, 0.5, col, vec3(0.35), vec3(0.8), vec3(0.6));  
    col = isometricCube(p+vec2(-0.9,0.1),offsetPos,size, 0.15, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.9,0.1),offsetPos,size*0.5, 0.6, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-1.3,0.3),offsetPos,size, 0.4, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-1.7,0.5),offsetPos,size, 0.1, col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    // car
    col = isometricCar(p,col);
    
    // buildings
    col = isometricCube(p+vec2(1.4,-0.4),offsetPos,size, 0.3, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(1.4,-0.4),offsetPos,size*0.5, 0.3, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(1.8,-0.2),offsetPos,size, 0.7, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.5,0.0),offsetPos,size, 0.3, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(0.9,0.2),offsetPos,size, 0.5, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(1.3,0.4),offsetPos,size, 0.4, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(1.7,0.6),offsetPos,size, 0.2, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(1.7,0.6),offsetPos,size*0.5, 0.3, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(0.1,0.2),offsetPos,size, 0.2, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.1,0.1),offsetPos,size*0.5, 0.1, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.3,0.4),offsetPos,size, 0.6, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.7,0.6),offsetPos,size, 0.15, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-1.1,0.8),offsetPos,size, 0.3, col, vec3(0.4), vec3(0.8), vec3(0.6)); 
    
    // chars
    float charH = 0.06;
    col = isometricCube(p+vec2(0.9,0.52),offsetPos,size*0.3, charH+animateVal(0.1), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.8,0.57),offsetPos,size*0.3, charH+animateVal(0.15), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.5,0.32),offsetPos,size*0.3, charH+animateVal(0.2), col, vec3(0.35), vec3(0.8), vec3(0.6));
    col = isometricCube(p+vec2(0.6,0.37),offsetPos,size*0.3, charH+animateVal(0.25), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.7,0.42),offsetPos,size*0.3, charH+animateVal(0.3), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.6,0.47),offsetPos,size*0.3, charH+animateVal(0.35), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.5,0.52),offsetPos,size*0.3, charH+animateVal(0.4), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.6,0.57),offsetPos,size*0.3, charH+animateVal(0.45), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.7,0.62),offsetPos,size*0.3, charH+animateVal(0.5), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.4,0.37),offsetPos,size*0.3, charH+animateVal(0.55), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.3,0.42),offsetPos,size*0.3, charH+animateVal(0.6), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(0.1,0.52),offsetPos,size*0.3, charH+animateVal(0.1), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.2,0.57),offsetPos,size*0.3, charH+animateVal(0.15), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.3,0.62),offsetPos,size*0.3, charH+animateVal(0.2), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.4,0.67),offsetPos,size*0.3, charH+animateVal(0.25), col, vec3(0.35), vec3(0.8), vec3(0.6));
    col = isometricCube(p+vec2(0.5,0.72),offsetPos,size*0.3, charH+animateVal(0.3), col, vec3(0.35), vec3(0.8), vec3(0.6));
    col = isometricCube(p+vec2(0.2,0.67),offsetPos,size*0.3, charH+animateVal(0.35), col, vec3(0.35), vec3(0.8), vec3(0.6));
    col = isometricCube(p+vec2(0.1,0.72),offsetPos,size*0.3, charH+animateVal(0.4), col, vec3(0.35), vec3(0.8), vec3(0.6));
    col = isometricCube(p+vec2(-0.2,0.67),offsetPos,size*0.3, charH+animateVal(0.45), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.1,0.72),offsetPos,size*0.3, charH+animateVal(0.5), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.0,0.77),offsetPos,size*0.3, charH+animateVal(0.55), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.1,0.82),offsetPos,size*0.3, charH+animateVal(0.6), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(0.2,0.87),offsetPos,size*0.3, charH+animateVal(0.65), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(-0.4,0.77),offsetPos,size*0.3, charH+animateVal(0.1), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.3,0.82),offsetPos,size*0.3, charH+animateVal(0.15), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.2,0.87),offsetPos,size*0.3, charH+animateVal(0.2), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.1,0.92),offsetPos,size*0.3, charH+animateVal(0.25), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(-0.2,0.97),offsetPos,size*0.3, charH+animateVal(0.3), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.3,1.02),offsetPos,size*0.3, charH+animateVal(0.35), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    col = isometricCube(p+vec2(0.0,0.97),offsetPos,size*0.3, charH+animateVal(0.4),  col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.5,0.82),offsetPos,size*0.3, charH+animateVal(0.45), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.6,0.87),offsetPos,size*0.3, charH+animateVal(0.5), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.7,0.92),offsetPos,size*0.3, charH+animateVal(0.55), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.6,0.97),offsetPos,size*0.3, charH+animateVal(0.6), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    col = isometricCube(p+vec2(-0.5,1.02),offsetPos,size*0.3, charH+animateVal(0.65), col, vec3(0.35), vec3(0.8), vec3(0.6)); 
    
    // results
    glFragColor = vec4(col,1.0);
}
