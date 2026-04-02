#version 420

// original https://www.shadertoy.com/view/ltcGRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool square(vec2 p, float w){
    if(abs(p.x) < w && abs(p.y) < w){
        return true;   
    }else{
        return false;
    }
}

//returns seemingly random float between 0.0 and 1.0
float randomNumber(float seed){
    float number = seed * seed * 16070.;
    float final = mod(number, 100.);
    return 0.01 * final;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x *= resolution.x / resolution.y;
    
    vec4 col = vec4(sin(time + uv.y) + 0.5) * .6;
    
    //SQUARES
    for(int i = 0; i < 9; i++){
        for(int j = 0; j < 6; j++){
            
            vec2 moveduv = uv - vec2(.25 * float(i - 1), -.2 + mod(.25 * float(j - 1) - time * .25, 1.5));

            //ROTATION
            vec2 rotateduv = vec2(0.0);
            
            float rot = time * 5.8 * (.5 - randomNumber(float(i + j + 185))); 

            rotateduv.x = moveduv.x * cos(rot) - moveduv.y * sin(rot);
            rotateduv.y = moveduv.y * cos(rot) + moveduv.x * sin(rot);

            vec2 newuv = rotateduv;

            if(square(newuv, mod(time / 15. + float(i) / 7. + float(j) /  13., .2)) == true){
                col += vec4(1. - mod(time / 15. + float(i) / 7. + float(j) /  13., .2) * 5.); 
            }
        }
    }

    glFragColor = col;
}
