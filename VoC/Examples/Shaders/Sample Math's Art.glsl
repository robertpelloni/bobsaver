#version 420

// original https://www.shadertoy.com/view/tdtSDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI             3.14159265359
#define smoothing      0.006
#define lineWidth      0.002

#define mainLinesColor vec3(0.8,0.2,0.1)
#define eLinesColor    vec3(0.6,0.8,0.1)
#define dotColors      vec3(0.1,0.3,0.)

void DrawPoint(vec2 pos, vec2 uv,float size, vec3 dotColor, inout vec3 sceneColor){
    
    float d    = distance(uv, pos);
    sceneColor = mix(dotColor, sceneColor, smoothstep(size, size +smoothing, d));
    
}

void DrawLine(float m, float c, vec2 uv, float size, vec3 lineColor, inout vec3 sceneColor){

    vec2  xy   = vec2(uv.x, uv.x * m + c); 
    float d    = distance(xy, uv);
    sceneColor = mix(lineColor, sceneColor, smoothstep(size, size + smoothing, d));
    
}

void DrawVector(vec2 origin, vec2 vector, vec2 uv, float size, vec3 lineColor, inout vec3 sceneColor){
    
          uv  -= origin;
    float v2   = dot(vector, vector);
    float vUv  = dot(vector, uv);
    vec2  p    = vector * vUv/v2;
    float d    = distance(p, uv);
    sceneColor = mix(lineColor, sceneColor, smoothstep(size, size +smoothing, d));
    
}

void DrawHalfVector(vec2 origin, vec2 vector, vec2 uv, float size, vec3 lineColor, inout vec3 sceneColor){
    
          uv  -= origin;
    float v2   = dot(vector, vector);
    float vUv  = dot(vector, uv);
    vec2  p    = vector * vUv/v2;
    float d    = distance(p, uv);
    float m    = 1. - step(0.,vUv/v2);
    sceneColor = mix(lineColor, sceneColor, clamp(smoothstep(size, size +smoothing, d)+ m, 0. ,1.)); 
}

void DrawHalfVectorWithLength(vec2 origin, vec2 vector, float len, vec2 uv, float size, vec3 lineColor, inout vec3 sceneColor){
    
          uv  -= origin;
    float v2   = dot(vector, vector);
    float vUv  = dot(vector, uv);
    vec2  p    = vector * vUv/v2;
    float d    = distance(p, uv);
    float m    = 1. - step(0.,vUv/v2);
          m   += step(len, vUv/v2);
    sceneColor = mix(lineColor, sceneColor, clamp(smoothstep(size, size + smoothing, d)+ m, 0. ,1.)); 
}

void DrawCurveSide(vec2 graphOrigin, vec2 uvCoordinate, float sideLengths, float numberOfPoints, vec2 side1, vec2 side2, inout vec3 col){
        float side2Sqr        = dot(side2, side2);
    
    DrawHalfVectorWithLength( graphOrigin, normalize( side1), sideLengths,uvCoordinate, lineWidth, mainLinesColor, col);
    DrawHalfVectorWithLength( graphOrigin, side2, sideLengths,uvCoordinate, lineWidth, mainLinesColor, col);
    
    

    for(float i = 1. ; i < numberOfPoints; i ++){
        
        float f    = (i / numberOfPoints);
        
        vec2 point = graphOrigin + normalize(side1) * f*sideLengths;
        
        DrawPoint(point, uvCoordinate, 0.01,dotColors, col); 
        
        // projection on the other line
        
             f        = 1.-f;
        vec2 endPoint = graphOrigin + normalize(side2) * f*sideLengths;
        

        DrawPoint(endPoint , uvCoordinate,  0.01,dotColors, col); 
        
        vec2 e    = point - endPoint; 
        
        DrawHalfVectorWithLength(endPoint, normalize(e), length(e), uvCoordinate,lineWidth*0.1, eLinesColor, col);
    }
}

void main(void)
{
    // ---------------------------------------------------------
    // ---COORDINATE SETUP
    
    vec2  uvCoordinate    =  gl_FragCoord.xy/resolution.xy;
    float aCorreection    =  resolution.x/resolution.y;
    
          uvCoordinate.x *=  aCorreection;
          uvCoordinate   -=  vec2(aCorreection/2., 0.5);
    
    // ---------------------------------------------------------
    vec3  col             = vec3(0.6,0.6,0.6);

    
    vec2  graphOrigin     = vec2(clamp(sin(time)*0.5, -1.,0.), 0.);
    float sideLengths     = 0.5;
    vec2  side1           = vec2(0., -1.);
    vec2  side2           = vec2(1.,0.);
    
    float numberOfPoints  = 12.* abs(sin(time*0.4));
   
    
    DrawCurveSide(graphOrigin, uvCoordinate, sideLengths, numberOfPoints, side1, side2, col);
    
          graphOrigin     = vec2(clamp(sin(time + PI)*0.5, -1.,0.), 0.);

          side1           = vec2(0., 1.);
          side2           = vec2(1.,0.);
    
    DrawCurveSide(graphOrigin, uvCoordinate, sideLengths, numberOfPoints, side1, side2, col);
    
       
          graphOrigin     = vec2(clamp(sin(time)*0.5, 0.,1.), 0.);

          side1           = vec2(0., 1.);
          side2           = vec2(-1.,0.);
    
    DrawCurveSide(graphOrigin, uvCoordinate, sideLengths, numberOfPoints, side1, side2, col);
    
          graphOrigin     = vec2(clamp(sin(time + PI)*0.5, 0.,1.), 0.);

          side1           = vec2(0., -1.);
          side2           = vec2(-1.,0.);
    
    DrawCurveSide(graphOrigin, uvCoordinate, sideLengths, numberOfPoints, side1, side2, col);
    
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
