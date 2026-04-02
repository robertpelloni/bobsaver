#version 420

// original https://www.shadertoy.com/view/MsX3DH

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float time2;
float width;
float height;
const float delta  = 0.0006;
const float PI =  3.14159265;

float sphere(vec3 position, float r)
{
        return length(position) - r ;//+ 0.53*sin(position.y*1.1 + mod(time2*0.2, 2.0*PI)-PI)
        //+ 0.17*sin(position.z*2.2 + mod(time2*0.02, 2.0*PI)-PI);
}

vec3 rotateX(vec3 pos, float alpha) {
    mat4 trans= mat4(1.0, 0.0, 0.0, 0.0,
                0.0, cos(alpha), -sin(alpha), 0.0,
                0.0, sin(alpha), cos(alpha), 0.0,
                0.0, 0.0, 0.0, 1.0);
                
                
    return vec3(trans * vec4(pos, 1.0));
}

vec3 rotateY(vec3 pos, float alpha) {

                
    mat4 trans2= mat4(cos(alpha), 0.0, sin(alpha), 0.0,
                0.0, 1.0, 0.0, 0.0,
                -sin(alpha), 0.0, cos(alpha), 0.0,
                0.0, 0.0, 0.0, 1.0);
                
    return vec3(trans2 * vec4(pos, 1.0));
}

vec3 translate(vec3 position, vec3 translation) {
    return position - translation;
}

float cube(vec3 pos,float size){
    return max(max(abs(pos.x)-size,abs(pos.y)-size),abs(pos.z)-size) ;//+ 0.17*sin(pos.z*2.2 + mod(time2*0.02, 2.0*PI)-PI);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}
/*
float function(vec3 position) {
    

    return  sdTorus(
            
            rotateX(
            rotateY(
            
            translate(position.xyz,vec3(0.0,0.0,20.0))
            ,
            time2* 2.3),position.x*0.8 + time2* 0.1)
            
            , vec2(4.0,2.0));
}*/

    

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float opRep( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    return sdSphere( q ,0.5);
}

    

float wonderCube(vec3 position) {

vec3 disp = vec3(0.0,0.0,8.9);

vec3 newPos = rotateY(rotateX(translate(position.xyz,disp),2.3*time2),1.8*time2);
return opS( opRep(newPos, vec3(1.2,1.2,1.2)),udRoundBox(newPos, vec3(2.2,2.2,2.2), 0.5))
;
}

float opCheapBend( vec3 p )
{
    float c = cos(1.9*(1.0+sin(time2*0.3))+p.y*0.19);
    float s = sin(1.9*(1.0+sin(time2*0.3))+p.y*0.18);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return wonderCube(q);
}

float opU( float d1, float d2 )
{
    return min(d1,d2);
}

float opTwist( vec3 p )
{
    float c = cos(0.90*p.y);
    float s = sin(0.90*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return wonderCube(q);
}

float opDisplace( vec3 p )
{
    float d1 = sdTorus(p, vec2(4.0,2.0));
    float d2 = (sin(p.x*3.0) + sin(p.y*5.0)) *0.2;
    return d1+d2;
}

float opBlend( vec3 position )
{
vec3 disp = vec3(0.0+4.0*sin(time2*2.2+3.0),0.0+2.0*sin(time2*1.3),8.0+0.3*sin(time2*1.5));

vec3 newPos = rotateY(rotateX(translate(position.xyz,disp),2.3*time2),1.8*time2);
    float d1 = wonderCube(position);
    vec3 p = position;
    float d2 = sin(0.800*p.x)*sin(0.800*p.y)*sin(0.800*p.z) ;
 
    return d1+d2;
}

float function(vec3 position) {
    

    return opCheapBend(position);

//return opBlend(position);

}

const vec3 lightDirection = vec3(-0.5,0.5,-1.0);

vec3 ray(vec3 start, vec3 direction, float t) {
    return start + t * direction;
}

vec3 gradient(vec3 position) {

    return vec3(function(position + vec3(delta, 0.0, 0.0)) - function(position - vec3(delta, 0.0, 0.0)),
    function(position + vec3(0.0,delta, 0.0)) - function(position - vec3(0.0, delta, 0.0)),
    function(position + vec3(0.0, 0.0, delta)) - function(position - vec3(0.0, 0.0, delta)));

    
}

vec4 plasma() {
 vec2 p = -1.0 +2.0 * gl_FragCoord.xy / vec2(640, 360);
float cossin1 = ((cos(p.x * 2.50 +time2*2.5) +sin(p.y*3.70-time2*4.5) +sin(time2*2.5))+3.0)/6.0;
float cossin2 = (cos(p.y * 2.30 +time2*3.5) +sin(p.x*2.90-time2*1.5) +cos(time2)+3.0)/6.0;
float cossin3 = (cos(p.x * 3.10 +time2*5.5) +0.5*sin(p.y*2.30-time2) +cos(time2*3.5)+3.0)/6.0;
return vec4(cossin1, cossin2, cossin3, 1.0);

}

void main()
{    
    time2 = time*0.4;
    width  = resolution.x;
    height = resolution.y;

    vec3 cameraPosition = vec3(0.0, 0.0, -1.4);
    
    float aspect = 360.0/640.0;
    vec3 nearPlanePosition = vec3((gl_FragCoord.x - 0.5 * width) / width * 2.0 ,
                                  (gl_FragCoord.y - 0.5 * height) / height * 2.0 * aspect,
                                   0.0);
                              
    vec3 viewDirection = normalize(nearPlanePosition - cameraPosition);
    
    float t = 0.0;
    float distance;
    vec3 position;
    vec4 color = plasma();//vec4(0.0,0.2,0.0,1);
    vec3 normal;
    vec3 up = normalize(vec3(-0.0, 1.0,0.0));
    
    for(int i=0; i < 64; i++) {
        position = ray(cameraPosition,    viewDirection, t);
        distance = function(position);
        
    
        
        if(abs(distance) < 0.005) {
            
                
            normal = normalize(gradient(position));
            
            vec4 color1 = vec4(0.5, 0.9, 0.5,1.0);
            vec4 color2 = vec4(1.0, 0.1, 0.1,1.0);
            
            vec4 color3 = mix(color2, color1, (1.0+dot(up, normal))/2.0);
            
            
            color = color3 * max(dot(normal, normalize(lightDirection)),0.0) +vec4(0.1,0.1,0.1,1.0);

            //specular
            vec3 E = normalize(cameraPosition - position);
            vec3 R = reflect(-normalize(lightDirection), normal);
            float specular = pow( max(dot(R, E), 0.0), 
                         8.0);
            color +=vec4(0.6, 0.4,0.4,0.0)*specular;
            break;
        }
        
            t = t + distance;
    }
                                  
                                  
    glFragColor = color;                                  
    //discard;
}
