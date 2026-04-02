#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define rot0(x) ((x*1)+(x/4294967296))
#define rot1(x) ((x*2)+(x/2147483648))
#define rot2(x) ((x*4)+(x/1073741824))
#define rot3(x) ((x*8)+(x/536870912))
#define rot4(x) ((x*16)+(x/268435456))
#define rot5(x) ((x*32)+(x/134217728))
#define rot6(x) ((x*64)+(x/67108864))
#define rot7(x) ((x*128)+(x/33554432))
#define rot8(x) ((x*256)+(x/16777216))
#define rot9(x) ((x*512)+(x/8388608))
#define rot10(x) ((x*1024)+(x/4194304))
#define rot11(x) ((x*2048)+(x/2097152))
#define rot12(x) ((x*4096)+(x/1048576))
#define rot13(x) ((x*8192)+(x/524288))
#define rot14(x) ((x*16384)+(x/262144))
#define rot15(x) ((x*32768)+(x/131072))
#define rot16(x) ((x*65536)+(x/65536))
#define rot17(x) ((x*131072)+(x/32768))
#define rot18(x) ((x*262144)+(x/16384))
#define rot19(x) ((x*524288)+(x/8192))
#define rot20(x) ((x*1048576)+(x/4096))
#define rot21(x) ((x*2097152)+(x/2048))
#define rot22(x) ((x*4194304)+(x/1024))
#define rot23(x) ((x*8388608)+(x/512))
#define rot24(x) ((x*16777216)+(x/256))
#define rot25(x) ((x*33554432)+(x/128))
#define rot26(x) ((x*67108864)+(x/64))
#define rot27(x) ((x*134217728)+(x/32))
#define rot28(x) ((x*268435456)+(x/16))
#define rot29(x) ((x*536870912)+(x/8))
#define rot30(x) ((x*1073741824)+(x/4))
#define rot31(x) ((x*2147483648)+(x/2))

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
                                          
}

mat3 rotationMatrixX( float angle){
    float s = sin(angle);
    float c = cos(angle);
    
    return mat3( 1, 0, 0,  
             0, c,-s,  
             0, s, c );
}

mat3 rotationMatrixY( float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat3( c, 0, s,  
                 0, 1, 0,  
                -s, 0, c );                               
}
mat3 rotationMatrixZ( float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat3( c,-s, 0,  
                 s, c, 0,  
                 0, 0, 1 );                               
}

float intersectSphere(vec3 rayOrigin, vec3 rayVector, vec3 sphereOrigin, float speherSize) 
    
{ 
        float t0, t1; // solutions for t if the ray intersects 
    speherSize*=speherSize;
    
        vec3 L = sphereOrigin - rayOrigin; // rayOrigin->sphereOrigin vector
        float tca = dot(L,rayVector);
    
        float d2 = dot(L,L) - tca * tca; 
        if (d2 > speherSize)
        return -1.0; 
        float thc = sqrt(speherSize - d2);
        t0 = tca - thc; 
        t1 = tca + thc;
    if(t0>0.0)
        return t0;
    else
        return t1;
       
} 

float intersectShit(vec3 rayOrigin, vec3 rayVector,vec3 v0,vec3 v1,vec3 v2){
    vec3 edge1=v1-v0;
    vec3 edge2=v2-v0;
    vec3 h=cross(rayVector,edge2);
    float a=dot(edge1,h);
    if(a==0.0){
        return -1.0; // This ray is parallel to this triangle.
    }
    float f=1.0/a;
    vec3 s = rayOrigin - v0;
    float u=f*dot(s,h);
    if(u<0.0 || u>1.0)
        return -1.0;
    vec3 q=cross(s,edge1);
    float v=f*dot(rayVector,q);
    if(v<0.0 || v>1.0)
        return -1.0;
    // At this stage we can compute t to find out where the intersection point is on the line.
    float t=f*dot(edge2,q);
    return f*dot(edge2,q);
    
}

vec3 randomVec3(int i){
    int a = i;
    a*=0x12345678;
    a*=(rot13(a)+rot27(i));
    a*=(rot12(a)+rot3(i));
    int b = i;
    b*=0x87654321;
    b*=(rot15(b)+rot25(i));
    b*=(rot13(b)+rot4(i));
    
    float ra = abs(float(a))*4.65661287308e-10;
    float rb = abs(float(b))*4.65661287308e-10;

    ra=ra*2.0-1.0;
    rb=rb*6.28318530718;
    float cra=sqrt(1.0-ra*ra);
    return vec3(ra,cos(rb)*cra,sin(rb)*cra);
    
    
}

void main( void ) {
    vec3 color;
    vec2 position = ( gl_FragCoord.xy / resolution.xy )-0.5;
    
    mat3 originMatrix=mat3(1,0,0,0,1,0,0,0,1);
    vec2 mice=mouse-0.5;
    originMatrix*=rotationMatrix(vec3(normalize(vec2(-mice.y,mice.x)),0.0),sqrt(dot(mice.xy,mice.xy))*5.0);

    
    const float sphereSize = 10.0;
    float ratio = resolution.x/resolution.y;
    float width = resolution.x;
    float height = resolution.y;
    float X = 0.0;
    float Y = 0.0;
    float Z = -3.0+sin(time*0.1);
    float RX = (-1.0 + gl_FragCoord.x*2.0/(resolution.x-1.0))*ratio*1.00 ;
    float RY = (-1.0 + gl_FragCoord.y*2.0/(resolution.y-1.0))*1.00 ;
    float RZ = 1.0;
    vec3 rayOrigin=vec3(X,Y,Z);
    vec3 rayVector=normalize(vec3(RX,RY,RZ));
    
    rayOrigin*=originMatrix;
    rayVector*=originMatrix;
    
    for(int i=0;i<10;i++){
        float depth=9999999999.0;
        float t;
        int i_object=-1;
        
        
        t=intersectSphere(rayOrigin,rayVector,vec3(0),1.0);
        if(t>0.0 && t<depth){depth=t;i_object=0;} // sphere
        
        t=intersectSphere(rayOrigin,rayVector,vec3(0),10.0);
        if(t>0.0 && t<depth){depth=t;i_object=1;} // sphere
        
        
        
        
        if(i_object==0 ){
            rayOrigin+=rayVector*depth;
            rayVector=reflect(rayVector,normalize(rayOrigin));
            rayOrigin+=0.01*rayVector;
            
        }
        else if(i_object==1){
                    
            vec3 intersection = rayOrigin+rayVector*depth;
            vec3 z = normalize(intersection);
            for(int i=0;i<40;i++){
                vec3 x = randomVec3(i);
                color=(dot(x,z)>0.9)?1.0-color:color;
            }
            
            
            break; 
        }
    }
    
    glFragColor += vec4( color, 1.0 );
        
        
        
    
}
