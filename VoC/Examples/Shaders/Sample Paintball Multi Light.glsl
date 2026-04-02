#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tljcWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hsv2rgb(h) clamp( abs(mod( h*6.+vec3(0,4,2), 6.)-3.)-1., 0., 1. )

const int nBalls = 40;
const int nLights = 4;
const int numColors = 3; //max 4
const float lightZ = -0.2;

float random (float i){
     return fract(sin(float(i)*43.0)*4790.234);   
}

float calcInfluence( vec4 ball, vec2 uv)
{ 
    float d = distance(ball.rg, uv);
    float inf = pow( ball.b/d, 3.0);
    return  inf;   
}

vec3 calcNormal( vec4 ball, vec2 uv )
{
    return vec3( ball.rg - uv, 0.1);      
}

vec3[] colors = vec3[]
(   

    vec3(255./255., 77./255., 0./255.),
    vec3(10./255., 84./255., 255./255.),
    vec3(255./255., 246./255., 0./255.),
    vec3(0./255., 192./255., 199./255.)
   
);

//for gradient?
vec3[] colors2 = vec3[]
(   

    vec3(230./255., 25./255., 56./255.),
    vec3(230./255., 144./255., 25./255.),
    vec3(0./255., 199./255., 152./255.),
    vec3(10./255., 165./255., 255./255.)
);

void main(void)
{
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv.x -= 0.333;
    vec4 mouse = vec4(0.0); //mouse*resolution.xy / resolution.yyyy;
    mouse.x -= 0.333;
    
       int i;
    
    //settings to play with!
    float threshold = 1.0;
    float shadowIntensity = 0.5; 
    float specularIntensity = 0.75;
    float specularPower = 300.0;
    float rimIntensity = 3.; //2
    float aoIntensity = 0.75; //75
    float ambientBrightness =  0.5 + 0.5 * uv.y;
    float lightFalloff = 0.5;
    
    bool rainbowMode = false;
    

       //balls
    float rad = 0.07;
    float rf = 0.005;
    float jiggle = sin(time*(2.0)) * 0.0125;
    
    float speed = 0.3;
    
    vec4[nBalls] balls;
    vec4[nLights] lights;
    
    for( i = 0; i < nBalls; i++ ){
    
        float per = float(i)/float(nBalls);
        float r = random( per * 7.0 + 0.32);
        float r2 = random( per * 11.0 + 0.87 );
        float r3 = random( per * 19.0 + 0.121 );
        float time = time + r * 11. + r2 * 21.;
        float x = 0.5 + sin(time*speed * (0.5 + 0.5 * r2))*(0.1 + 0.9 * r);
        float y = 0.5 + cos(time*speed * (0.5 + 0.5 * r3))*(0.1 + 0.9 * r2);
 
        int color = i % numColors;
        float rd = rad + 0.9 * rad * sin(time*0.2 + r*13.0)*r;
        
        balls[i] = vec4( x, y, rd, color );
        
    }
    
    for( i = 0; i < nLights; i++ ){
    
        float per = float(i)/float(nBalls);
        float r = random( per * 21.0 + 17.0 );
        float r2 = random( per * 31.0 + 13.0 );
        float r3 = random( per * 41.0 + 3.0 );
        float time = time + r * 21. + r2 * 11.;
        float x = 0.5 + sin(time*speed * (0.5 + 0.5 * r2))*(0.1 + 0.9 * r);
        float y = 0.5 + cos(time*speed * (0.5 + 0.5 * r3))*(0.1 + 0.9 * r2);
 
        lights[i] = vec4( x, y, 0.01, 1.0 );
        
    }

    
    int ballCount = nBalls;
    
    int accumulatorCount = 4;
    float[] accumulators = float[]
    (
        0.0,
        0.0,
        0.0,
        0.0
    );
    
    vec3[] shaders = vec3[]
    (
        vec3(0),
        vec3(0),
        vec3(0),
        vec3(0)
    );
    
    

    //determine color with greatest influence
    for( i = 0; i < ballCount; i++ )
    {
        int idx = int( balls[i].a );
        float inf = calcInfluence( balls[i], uv);  
        accumulators[idx] += inf;
        shaders[idx] += calcNormal( balls[i], uv) * inf;
    }
    
    float maxInf = 0.0;
    int maxIdx = 0;
    vec3 avgColor = vec3(0,0,0);
    float totalInf = 0.0;
    
    for( i = 0; i < accumulatorCount; i++ )
    {
        if( accumulators[i] > maxInf )
        {
            maxInf = accumulators[i];
            maxIdx = i;
        }
        
        totalInf += accumulators[i];
        avgColor += accumulators[i] * colors[i];
    }
    
    avgColor /= totalInf;
    
    float influence = accumulators[maxIdx];
    vec3 baseColor = colors[maxIdx];
    vec3 normal = normalize(shaders[maxIdx]);
 
      
  
    //basecolor
    vec3 color = baseColor;
    vec3 ambientColor = vec3(ambientBrightness);
    if( rainbowMode )
        ambientColor = avgColor * ambientBrightness;
   
    //rim light
    float rim = 1.0 - (dot ( vec3(0.,0.,-1.), -normal));
    color += vec3(1.0) * rimIntensity * pow (rim, 2.0);
    
    color = color * (1.0 - shadowIntensity);
    
    for( i = 0; i < nLights; i++ )
    {
        vec4 light = lights[i];
        vec3 lightDir = normalize( vec3(light.xy, lightZ) - vec3( uv, 0.0 ) ); 
        float intensity = min( 1.0, (lightFalloff * light.w) / pow( distance( light.xy, uv ), 2.0 ));
        
        //diffuse
        float lighting = max(0.,dot( -normal, lightDir) );
        lighting *= intensity;
        color += max( (baseColor * lighting) - color, vec3(0.) );
  
        // specular blinn phong
        vec3 dir = normalize(lightDir + vec3(0,0,-1.0) );
        float specAngle = max(dot(dir, -normal), 0.0);
        float specular = pow(specAngle, specularPower);
        color += vec3(1.0) * specular * specularIntensity * intensity;
    }
    
   
    
    
    //ao
    float prox = (maxInf/totalInf);
    prox = pow( smoothstep( 1.0, 0.35, prox), 3.0 );
    vec3 aoColor = vec3(0.0);
    color = mix( color , aoColor, prox * aoIntensity);
    
    //shape
    float aa = min( fwidth( influence ) * 1.5, 1.);
       float smo = smoothstep( 0., aa, influence - threshold);
    color = mix( ambientColor, color, smo);
    
    
    for( i = 0; i < nLights; i++ )
    {
        vec4 light = lights[i];
        float lightIntensity = calcInfluence( light, uv );
           color += pow(lightIntensity,0.5) * 1.0 * light.w;    
    }
    
                    
    
    glFragColor = vec4( color, 1.0 );
    
}
