import math
import torch
from basicsr.archs import build_network
from basicsr.models.base_model import BaseModel
from basicsr.utils import get_root_logger
from basicsr.utils.registry import MODEL_REGISTRY
from torch.nn import functional as F
from torchvision.ops import roi_align


@MODEL_REGISTRY.register()
class GFPGANModel(BaseModel):
    """The GFPGAN model for Towards real-world blind face restoratin with generative facial prior"""

    def __init__(self, opt):
        super(GFPGANModel, self).__init__(opt)
        self.idx = 0  # it is used for saving data for check

        # define network
        self.net_g = build_network(opt["network_g"])
        self.net_g = self.model_to_device(self.net_g)
        self.print_network(self.net_g)

        # load pretrained model
        load_path = self.opt["path"].get("pretrain_network_g", None)
        if load_path is not None:
            param_key = self.opt["path"].get("param_key_g", "params")
            self.load_network(
                self.net_g,
                load_path,
                self.opt["path"].get("strict_load_g", True),
                param_key,
            )

        self.log_size = int(math.log(self.opt["network_g"]["out_size"], 2))

    def feed_data(self, data):
        self.lq = data["lq"].to(self.device)
        if "gt" in data:
            self.gt = data["gt"].to(self.device)

        if "loc_left_eye" in data:
            # get facial component locations, shape (batch, 4)
            self.loc_left_eyes = data["loc_left_eye"]
            self.loc_right_eyes = data["loc_right_eye"]
            self.loc_mouths = data["loc_mouth"]

        # uncomment to check data
        # import torchvision
        # if self.opt['rank'] == 0:
        #     import os
        #     os.makedirs('tmp/gt', exist_ok=True)
        #     os.makedirs('tmp/lq', exist_ok=True)
        #     print(self.idx)
        #     torchvision.utils.save_image(
        #         self.gt, f'tmp/gt/gt_{self.idx}.png', nrow=4, padding=2, normalize=True, range=(-1, 1))
        #     torchvision.utils.save_image(
        #         self.lq, f'tmp/lq/lq{self.idx}.png', nrow=4, padding=2, normalize=True, range=(-1, 1))
        #     self.idx = self.idx + 1

    def construct_img_pyramid(self):
        """Construct image pyramid for intermediate restoration loss"""
        pyramid_gt = [self.gt]
        down_img = self.gt
        for _ in range(0, self.log_size - 3):
            down_img = F.interpolate(
                down_img, scale_factor=0.5, mode="bilinear", align_corners=False
            )
            pyramid_gt.insert(0, down_img)
        return pyramid_gt

    def get_roi_regions(self, eye_out_size=80, mouth_out_size=120):
        face_ratio = int(self.opt["network_g"]["out_size"] / 512)
        eye_out_size *= face_ratio
        mouth_out_size *= face_ratio

        rois_eyes = []
        rois_mouths = []
        for b in range(self.loc_left_eyes.size(0)):  # loop for batch size
            # left eye and right eye
            img_inds = self.loc_left_eyes.new_full((2, 1), b)
            bbox = torch.stack(
                [self.loc_left_eyes[b, :], self.loc_right_eyes[b, :]], dim=0
            )  # shape: (2, 4)
            rois = torch.cat([img_inds, bbox], dim=-1)  # shape: (2, 5)
            rois_eyes.append(rois)
            # mouse
            img_inds = self.loc_left_eyes.new_full((1, 1), b)
            rois = torch.cat(
                [img_inds, self.loc_mouths[b : b + 1, :]], dim=-1
            )  # shape: (1, 5)
            rois_mouths.append(rois)

        rois_eyes = torch.cat(rois_eyes, 0).to(self.device)
        rois_mouths = torch.cat(rois_mouths, 0).to(self.device)

        # real images
        all_eyes = (
            roi_align(self.gt, boxes=rois_eyes, output_size=eye_out_size) * face_ratio
        )
        self.left_eyes_gt = all_eyes[0::2, :, :, :]
        self.right_eyes_gt = all_eyes[1::2, :, :, :]
        self.mouths_gt = (
            roi_align(self.gt, boxes=rois_mouths, output_size=mouth_out_size)
            * face_ratio
        )
        # output
        all_eyes = (
            roi_align(self.output, boxes=rois_eyes, output_size=eye_out_size)
            * face_ratio
        )
        self.left_eyes = all_eyes[0::2, :, :, :]
        self.right_eyes = all_eyes[1::2, :, :, :]
        self.mouths = (
            roi_align(self.output, boxes=rois_mouths, output_size=mouth_out_size)
            * face_ratio
        )

    def _gram_mat(self, x):
        """Calculate Gram matrix.

        Args:
            x (torch.Tensor): Tensor with shape of (n, c, h, w).

        Returns:
            torch.Tensor: Gram matrix.
        """
        n, c, h, w = x.size()
        features = x.view(n, c, w * h)
        features_t = features.transpose(1, 2)
        gram = features.bmm(features_t) / (c * h * w)
        return gram

    def gray_resize_for_identity(self, out, size=128):
        out_gray = (
            0.2989 * out[:, 0, :, :]
            + 0.5870 * out[:, 1, :, :]
            + 0.1140 * out[:, 2, :, :]
        )
        out_gray = out_gray.unsqueeze(1)
        out_gray = F.interpolate(
            out_gray, (size, size), mode="bilinear", align_corners=False
        )
        return out_gray

    def test(self):
        with torch.no_grad():
            if hasattr(self, "net_g_ema"):
                self.net_g_ema.eval()
                self.output, _ = self.net_g_ema(self.lq)
            else:
                logger = get_root_logger()
                logger.warning("Do not have self.net_g_ema, use self.net_g.")
                self.net_g.eval()
                self.output, _ = self.net_g(self.lq)
                self.net_g.train()
