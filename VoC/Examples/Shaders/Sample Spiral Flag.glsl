#version 420

// original https://www.shadertoy.com/view/Mc2Bzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159;
float TAU = 2.*3.14159;
const int N = 4;

// SDF from IQ
float sdPolygon( in vec2[N] v, in vec2 p )
{
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=N-1; i<N; j=i, i++ )
    {
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        bvec3 c = bvec3(p.y>=v[i].y,p.y<v[j].y,e.x*w.y>e.y*w.x);
        if( all(c) || all(not(c)) ) s*=-1.0;  
    }
    return s*sqrt(d);
}

void main(void)
{
   vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy ) /resolution.y;
   vec3 col = vec3(0.);   
   float tt = fract(.3*time);
     
   float scale =20.;
   uv *= scale;  
   vec2 cellID = round(uv);
   uv = fract(uv +.5) - .5;
   
   float nS = 2.;
   float minVal = 1E20;
   float nCheck = 1.;
   for (float i = -nCheck; i <= nCheck; i++)
     for(float j = -nCheck; j <= nCheck; j++){ 
       vec2 uvCenter = (cellID + vec2(i,j)) / scale;
       float xCutoff = .7;
       float yCutOff = xCutoff/(resolution.x/resolution.y);
       if (abs(uvCenter.x) < xCutoff && abs(uvCenter.y) < yCutOff){
         float centerDelta = TAU*(tt - 2.*length(uvCenter))+ atan(uvCenter.y,uvCenter.x) + PI ;
         // centerDelta = PI/2.;

         float meshDim = clamp(.35 + .35*sin(centerDelta),0.,.5); 
         
         vec2 p1 = uvCenter + vec2(-meshDim/scale,meshDim/scale);
         vec2 p2 = uvCenter + vec2(-meshDim/scale,-meshDim/scale);
         vec2 p3 = uvCenter + vec2(meshDim/scale,-meshDim/scale);
         vec2 p4 = uvCenter + vec2(meshDim/scale,meshDim/scale);      
         
         float v1delta = TAU*(tt - 2.*length(p1)) + atan(p1.y,p1.x) + PI ;
         float v2delta = TAU*(tt - 2.*length(p2)) + atan(p2.y,p2.x) + PI ;
         float v3delta = TAU*(tt - 2.*length(p3)) + atan(p3.y,p3.x) + PI ;
         float v4delta = TAU*(tt - 2.*length(p4)) + atan(p4.y,p4.x) + PI ;

         vec2[4] verts; 
         float r = .5;
         verts[0] = vec2(i,j) + vec2(-meshDim,meshDim) + vec2(r*cos(v1delta),r*sin(v1delta));
         verts[1] = vec2(i,j) + vec2(-meshDim,-meshDim)+ vec2(r*cos(v2delta),r*sin(v2delta));
         verts[2] = vec2(i,j) + vec2(meshDim, -meshDim)+ vec2(r*cos(v3delta),r*sin(v3delta));
         verts[3] = vec2(i,j) + vec2(meshDim, meshDim) + vec2(r*cos(v4delta),r*sin(v4delta));
         float poly = sdPolygon(verts, uv);
         minVal = min(poly, minVal);
       }
     }
     
   
     col += .035/abs(minVal);
     glFragColor = vec4(col,1.0);
   
} 
