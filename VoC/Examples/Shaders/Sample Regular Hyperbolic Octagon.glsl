#version 420

// original https://www.shadertoy.com/view/dlcGzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float gamma = 5. + 4.*sqrt(2.0);
const float gammabeta = sqrt(gamma*gamma-1.0);

const float beta = gammabeta/gamma;
const float eta = .5 * log((1.+beta)/(1.-beta));

const float PI_4 = 0.78539816339 ;

const float INVSQRT2 = 1.0/sqrt(2.0);

vec3 fundamental_domain(vec2 w){
    float wnorm2 = dot(w,w);
    float wnorm = sqrt(wnorm2);
    float l = log((1.+wnorm)/(1.-wnorm));
    
    vec3 tone = vec3(w.x,.25+.333*w.y,-w.y)/wnorm;
    
    return (.5 + .5*(fract(4.*l))) * tone;
}

vec3 pix(){
    vec2 z_flat = 2.*((gl_FragCoord.xy-resolution.xy*.5) / resolution.y);
    float norm2z = dot(z_flat,z_flat);
    if(norm2z>1.)
    {
        return vec3(0.,0.,0.);
        
    }

    vec3 z = vec3( 2.*z_flat, 1.+ norm2z)/(1.-norm2z);
    
    float tl = (fract(0.1*time-.5)-.5) * eta;
    float etl = .5*exp(tl);
    float emtl = .5*exp(-tl);
    float tlgamma = etl + emtl;
    float tlgammabeta = etl - emtl;
    
    z = vec3(z.z*tlgammabeta + z.x*tlgamma, z.y,z.z*tlgamma + z.x*tlgammabeta);
    
    
    for(int i=0; i<25; i++){
        float t = z.z;
        bool has_transformed = false;
        
        for(int j = 0; j< 8; j++){
            
            
            
            float nt = gamma * z.z - gammabeta * z.x;

            if(nt < t){
                z = vec3(- gammabeta*z.z + gamma * z.x ,z.y, nt);
                has_transformed = true;
                
                float angle = float(j) * PI_4;
                float c = cos(angle);
                float s = sin(angle);
                
                z.xy = vec2(c*z.x - s * z.y, s*z.x + c *z.y);
                break;
            }
            
           
            
            z.xy = INVSQRT2 * vec2(z.x+z.y, -z.x+z.y);
        }
        
        if(!has_transformed)
            break;
    
    }

    vec2 w = z.xy/(1.+z.z);
    return fundamental_domain(w);

}

void main(void)
{
    vec3 col = pix();
    glFragColor = vec4(col,1.0);
}