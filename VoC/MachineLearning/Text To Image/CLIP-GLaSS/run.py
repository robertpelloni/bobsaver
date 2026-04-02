import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import argparse
import os
import sys
import torch
import numpy as np
import pickle
from pymoo.optimize import minimize
from pymoo.algorithms.so_genetic_algorithm import GA
from pymoo.factory import get_algorithm, get_decision_making, get_decomposition
from pymoo.visualization.scatter import Scatter

from config import get_config
from problem import GenerationProblem
from operators import get_operators

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning) 

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

parser = argparse.ArgumentParser()

parser.add_argument("--device", type=str, default="cuda")
parser.add_argument("--config", type=str, default="DeepMindBigGAN512")
parser.add_argument("--generations", type=int, default=500)
parser.add_argument("--save-each", type=int, default=10)
parser.add_argument("--tmp-folder", type=str, default=".")
parser.add_argument("--target", type=str, default="a wolf at night with the moon in the background")
parser.add_argument('--seed', type=int, help='Random seed.')

config = parser.parse_args()
vars(config).update(get_config(config.config))


if config.seed is not None:
    sys.stdout.write(f'Setting seed to {config.seed} ...\n')
    sys.stdout.flush()
    import numpy as np
    np.random.seed(config.seed)
    import random
    random.seed(config.seed)
    #next line forces deterministic random values, but causes other issues with resampling (uncomment to see)
    #torch.use_deterministic_algorithms(True)
    torch.manual_seed(config.seed)
    torch.cuda.manual_seed(config.seed)
    torch.cuda.manual_seed_all(config.seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False 



iteration = 0
def save_callback(algorithm):
    global iteration
    global config

    iteration += 1

    sys.stdout.write("Iteration {}".format(iteration)+"\n")
    #sys.stdout.flush()
    
    sys.stdout.flush()	
    if iteration % config.save_each == 0 or iteration == config.generations:
        sys.stdout.flush()
        sys.stdout.write("Saving progress ...\n")
        sys.stdout.flush()
        
        if config.problem_args["n_obj"] == 1:
            sortedpop = sorted(algorithm.pop, key=lambda p: p.F)
            X = np.stack([p.X for p in sortedpop])  
        else:
            X = algorithm.pop.get("X")
        
        ls = config.latent(config)
        ls.set_from_population(X)

        with torch.no_grad():
            generated = algorithm.problem.generator.generate(ls, minibatch=config.batch_size)
            if config.task == "txt2img":
                ext = "jpg"
            elif config.task == "img2txt":
                ext = "txt"
            #name = "genetic-it-%d.%s" % (iteration, ext) if iteration < config.generations else "genetic-it-final.%s" % (ext, )
            name = "Progress."+ext
            algorithm.problem.generator.save(generated, os.path.join(config.tmp_folder, name))
        
        sys.stdout.flush()
        sys.stdout.write("Progress saved\n")
        sys.stdout.flush()
        

sys.stdout.write("Getting ready ...\n")
sys.stdout.flush()

problem = GenerationProblem(config)
operators = get_operators(config)

if not os.path.exists(config.tmp_folder): os.mkdir(config.tmp_folder)

algorithm = get_algorithm(
    config.algorithm,
    pop_size=config.pop_size,
    sampling=operators["sampling"],
    crossover=operators["crossover"],
    mutation=operators["mutation"],
    eliminate_duplicates=True,
    callback=save_callback,
    **(config.algorithm_args[config.algorithm] if "algorithm_args" in config and config.algorithm in config.algorithm_args else dict())
)

res = minimize(
    problem,
    algorithm,
    ("n_gen", config.generations),
    save_history=False,
    verbose=False,
)

'''
pickle.dump(dict(
    X = res.X,
    F = res.F,
    G = res.G,
    CV = res.CV,
), open(os.path.join(config.tmp_folder, "genetic_result"), "wb"))

if config.problem_args["n_obj"] == 2:
    plot = Scatter(labels=["similarity", "discriminator",])
    plot.add(res.F, color="red")
    plot.save(os.path.join(config.tmp_folder, "F.jpg"))

'''

if config.problem_args["n_obj"] == 1:
    sortedpop = sorted(res.pop, key=lambda p: p.F)
    X = np.stack([p.X for p in sortedpop])
else:
    X = res.pop.get("X")

ls = config.latent(config)
ls.set_from_population(X)

#torch.save(ls.state_dict(), os.path.join(config.tmp_folder, "ls_result"))

if config.problem_args["n_obj"] == 1:
    X = np.atleast_2d(res.X)
else:
    try:
        result = get_decision_making("pseudo-weights", [0, 1]).do(res.F)
    except:
        print("Warning: cant use pseudo-weights")
        result = get_decomposition("asf").do(res.F, [0, 1]).argmin()

    X = res.X[result]
    X = np.atleast_2d(X)

ls.set_from_population(X)

sys.stdout.write("Starting ...\n")
sys.stdout.flush()

with torch.no_grad():
    generated = problem.generator.generate(ls)


if config.task == "txt2img":
    ext = "jpg"
elif config.task == "img2txt":
    ext = "txt"

#problem.generator.save(generated, os.path.join(config.tmp_folder, "output.%s" % (ext)))