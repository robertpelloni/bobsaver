#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3t2cDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hsv2rgb(h) clamp( abs(mod( h*6.+vec3(0,4,2), 6.)-3.)-1., 0., 1. )

const int nBalls = 40;
const int numColors = 2; //max 4

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
    vec3(255./255., 246./255., 0./255.),
    vec3(0./255., 192./255., 199./255.),
    vec3(10./255., 84./255., 255./255.)
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
    float specularIntensity = 0.3;
    float specularPower = 50.0;
    float rimIntensity = 2.; //2
    float aoIntensity = 0.5;
    float ambientBrightness =  0.05;
    
    bool rainbowMode = false;
    

       //balls
    float rad = 0.09;
    float rf = 0.005;
    float jiggle = sin(time*(2.0)) * 0.0125;
    
    float speed = 0.25;
    
    vec4[nBalls] balls;
    
    for( i = 0; i < nBalls; i++ ){
    
        float per = float(i)/float(nBalls);
        float r = random( per * 7.0 );
        float r2 = random( per * 11.0 );
        float r3 = random( per * 19.0 );
        
        float x = 0.5 + sin(time*speed + r*30.0)*r;
        float y = 0.5 + cos(time*speed + r*40.0)*r2*0.5;
 
        int color = i % numColors;
        float rd = rad + 0.5 * rad * sin(time*speed + r*13.0)*r;
        
        balls[i] = vec4( x, y, rd, color );
        
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
 
      
    //point light
    vec3 light = vec3( mouse.x, mouse.y, -0.25);
    float lightRadius = 0.01;
    float lightIntensity = calcInfluence( vec4(light.x, light.y, lightRadius, 0.), uv );
    vec3 lightDir = normalize( light - vec3( uv, 0.0 ) );                
    
    //basecolor
    vec3 color = baseColor;
    vec3 ambientColor = vec3(ambientBrightness);
    if( rainbowMode )
        ambientColor = avgColor * ambientBrightness;
   
    //rim light
    float rim = 1.0 - (dot ( vec3(0.,0.,-1.), -normal));
    color += vec3(1.0) * rimIntensity * pow (rim, 2.0);
    
    //diffuse
    float lighting = max(0.,dot( -normal, lightDir) );
    color = mix( color, color * lighting, (1.0 - ambientBrightness) * shadowIntensity );
    
    // specular blinn phong
    vec3 dir = normalize(lightDir + vec3(0,0,-1.0) );
    float specAngle = max(dot(dir, -normal), 0.0);
    float specular = pow(specAngle, specularPower);
    color += vec3(1.0) * specular * specularIntensity;
    
    //ao
    float prox = (maxInf/totalInf);
    prox = pow( smoothstep( 1.0, 0.35, prox), 3.0 );
    vec3 aoColor = vec3(0.0);
    color = mix( color , aoColor, prox * aoIntensity);
    
    //shape
    float aa = min( fwidth( influence ) * 1.5, 1.);
       float smo = smoothstep( 0., aa, influence - threshold);
    color = mix( ambientColor, color, smo);
    
    color += pow(lightIntensity,0.5) * 2.0 * vec3(1.);                    
    
    glFragColor = vec4( color, 1.0 );
    
}
